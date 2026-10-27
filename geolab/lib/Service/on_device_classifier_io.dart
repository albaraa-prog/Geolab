import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the distilled multi-head model (Model_trainig/distillation) on the
/// device. The model and its manifest are bundled under assets/models/;
/// [load] returns null when they are missing, so the app falls back to the
/// server.
///
/// The decision logic matches the API: stage 1 rock check, stage 2
/// subcategory with soft routing to the runner-up, stage 3 subclass within
/// the chosen subcategory. The heatmap comes from the class activation maps
/// the model outputs, so no gradients are needed on the phone.
class OnDeviceClassifier {
  static const _modelAsset = 'assets/models/geolab_student.tflite';
  static const _manifestAsset = 'assets/models/manifest.json';

  final Interpreter _interpreter;
  final Map<String, dynamic> _manifest;
  final Map<String, int> _outputIndex;

  OnDeviceClassifier._(this._interpreter, this._manifest, this._outputIndex);

  static OnDeviceClassifier? _instance;

  static Future<OnDeviceClassifier?> load() async {
    if (_instance != null) return _instance;
    try {
      final manifest = jsonDecode(await rootBundle.loadString(_manifestAsset)) as Map<String, dynamic>;
      if (manifest['kind'] != 'multihead') return null;
      final interpreter = await Interpreter.fromAsset(_modelAsset, options: InterpreterOptions()..threads = 2);
      _instance = OnDeviceClassifier._(interpreter, manifest, _mapOutputs(interpreter, manifest));
      return _instance;
    } catch (_) {
      return null; // Model not bundled or not loadable
    }
  }

  /// Output order is not guaranteed after conversion, so match by shape
  static Map<String, int> _mapOutputs(Interpreter interpreter, Map<String, dynamic> manifest) {
    final layout = (manifest['layout'] as List).cast<Map<String, dynamic>>();
    final subclasses = layout.fold<int>(0, (sum, g) => sum + (g['count'] as int));
    final subcategories = (manifest['subcategories'] as List).length;
    final wanted = <String, List<int>>{
      'stage1': [1, 2],
      'stage2': [1, subcategories],
      'stage3': [1, subclasses],
      'cam2': [1, subcategories, 7, 7],
      'cam3': [1, subclasses, 7, 7],
    };
    final tensors = interpreter.getOutputTensors();
    final index = <String, int>{};
    wanted.forEach((name, shape) {
      for (var i = 0; i < tensors.length; i++) {
        if (!index.containsValue(i) && _sameShape(tensors[i].shape, shape)) {
          index[name] = i;
          break;
        }
      }
    });
    if (index.length != wanted.length) {
      throw StateError('Unexpected model outputs: ${tensors.map((t) => t.shape).toList()}');
    }
    return index;
  }

  static bool _sameShape(List<int> a, List<int> b) =>
      a.length == b.length && List.generate(a.length, (i) => a[i] == b[i]).every((x) => x);

  /// Classify an encoded image (JPEG/PNG). Returns the same map shape as the
  /// API response: stage1, stage2, stage3, final_prediction, gradcam.
  Future<Map<String, dynamic>> classify(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Image processing failed: unreadable image');
    final size = _manifest['input_size'] as int;
    final resized = _prepare(img.bakeOrientation(decoded), size);
    final input = _toTensor(resized).reshape([1, 3, size, size]);

    final tensors = _interpreter.getOutputTensors();
    final outputs = <int, Object>{};
    for (var i = 0; i < tensors.length; i++) {
      final shape = tensors[i].shape;
      outputs[i] = List<double>.filled(shape.reduce((a, b) => a * b), 0).reshape(shape);
    }
    _interpreter.runForMultipleInputs([input], outputs);

    List<double> flat(String name) => _flatten(outputs[_outputIndex[name]!]!);
    return _decide(flat('stage1'), flat('stage2'), flat('stage3'), flat('cam2'), flat('cam3'), resized);
  }

  /// Same preprocessing as the server: shrink to 256 px, then 224x224
  img.Image _prepare(img.Image image, int size) {
    final limit = _manifest['resize_max'] as int;
    final longest = math.max(image.width, image.height);
    if (longest > limit) {
      final scale = limit / longest;
      image = img.copyResize(image,
          width: (image.width * scale).round(), height: (image.height * scale).round(),
          interpolation: img.Interpolation.cubic);
    }
    return img.copyResize(image, width: size, height: size, interpolation: img.Interpolation.linear);
  }

  Float32List _toTensor(img.Image image) {
    final mean = (_manifest['mean'] as List).map((v) => (v as num).toDouble()).toList();
    final std = (_manifest['std'] as List).map((v) => (v as num).toDouble()).toList();
    final w = image.width, h = image.height, plane = w * h;
    final data = Float32List(3 * plane);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final i = y * w + x;
        data[i] = (p.r.toDouble() / 255.0 - mean[0]) / std[0];
        data[plane + i] = (p.g.toDouble() / 255.0 - mean[1]) / std[1];
        data[2 * plane + i] = (p.b.toDouble() / 255.0 - mean[2]) / std[2];
      }
    }
    return data;
  }

  Map<String, dynamic> _decide(List<double> s1, List<double> s2, List<double> s3, List<double> cam2,
      List<double> cam3, img.Image resized) {
    final names = (_manifest['subcategories'] as List).cast<String>();
    final layout = (_manifest['layout'] as List).cast<Map<String, dynamic>>();
    final subclasses = (_manifest['subclasses'] as Map).cast<String, dynamic>();
    final threshold = ((_manifest['thresholds'] as Map)['stage1'] as num).toDouble();

    final p1 = _softmax(s1);
    final rockConfidence = p1[1];
    final result = <String, dynamic>{
      'on_device': true,
      'stage1': {
        'is_rock': rockConfidence >= threshold,
        'confidence': rockConfidence,
        'probabilities': {'non_rock': p1[0], 'rock': rockConfidence},
      },
    };
    if (rockConfidence < threshold) {
      result['final_prediction'] = {
        'classification': 'non-rock',
        'subclass': null,
        'main_category': null,
        'confidence': 1 - rockConfidence,
      };
      return result;
    }

    final p2 = _softmax(s2);
    final order = List.generate(p2.length, (i) => i)..sort((a, b) => p2[b].compareTo(p2[a]));
    final best2 = order[0];
    result['stage2'] = {
      'subcategory': names[best2],
      'main_category': names[best2].split('_').first,
      'confidence': p2[best2],
      'probabilities': {for (var i = 0; i < names.length; i++) names[i]: p2[i]},
    };
    final candidates = [best2, if (p2[order[0]] < 0.6 && p2[order[1]] > 0.15) order[1]];

    double? bestScore;
    int? bestGroup, bestIndex;
    List<double>? bestProbs;
    for (final g in candidates) {
      final offset = layout[g]['offset'] as int, count = layout[g]['count'] as int;
      if (count == 0) continue;
      final probs = _softmax(s3.sublist(offset, offset + count));
      final idx = _argmax(probs);
      final score = (p2[g] + probs[idx]) / 2 + (probs[idx] > 0.9 ? 0.1 : 0.0);
      if (bestScore == null || score > bestScore) {
        bestScore = score;
        bestGroup = g;
        bestIndex = idx;
        bestProbs = probs;
      }
    }

    if (bestGroup == null) {
      final main = names[best2].split('_').first;
      result['final_prediction'] = {
        'classification': 'rock-$main',
        'subclass': null,
        'main_category': main,
        'confidence': p2[best2],
      };
      result['gradcam'] = _heatmap(cam2, best2, resized, 2, names[best2]);
      return result;
    }

    final subcategory = names[bestGroup];
    final main = subcategory.split('_').first;
    final classes = (subclasses[subcategory] as List).cast<String>();
    final index = bestIndex!;
    final probs = bestProbs!;
    final name = classes[index];
    result['stage3'] = {
      'subcategory': subcategory,
      'subclass': name,
      'subclass_index': index,
      'confidence': probs[index],
      'probabilities': {for (var i = 0; i < classes.length; i++) classes[i]: probs[i]},
    };
    result['final_prediction'] = {
      'classification': 'rock-$main-$name',
      'subclass': name,
      'main_category': main,
      'confidence': probs[index],
    };
    final global = (layout[bestGroup]['offset'] as int) + index;
    result['gradcam'] = _heatmap(cam3, global, resized, 3, name);
    return result;
  }

  /// Heatmap for one class, in the format GradCamView expects
  Map<String, dynamic> _heatmap(List<double> cams, int classIndex, img.Image resized, int stage, String label) {
    const cells = 49;
    final cam = cams.sublist(classIndex * cells, (classIndex + 1) * cells).map((v) => math.max(v, 0.0)).toList();
    final lo = cam.reduce((a, b) => math.min(a, b)), hi = cam.reduce((a, b) => math.max(a, b));
    final small = img.Image(width: 7, height: 7, numChannels: 1);
    for (var i = 0; i < cells; i++) {
      small.setPixelR(i % 7, i ~/ 7, ((cam[i] - lo) / (hi - lo + 1e-8) * 255).round());
    }
    final big = img.copyResize(small, width: resized.width, height: resized.height,
        interpolation: img.Interpolation.linear);
    final colored = img.Image(width: resized.width, height: resized.height);
    for (var y = 0; y < big.height; y++) {
      for (var x = 0; x < big.width; x++) {
        final v = big.getPixel(x, y).r.toDouble() / 255.0;
        colored.setPixelRgb(x, y, _jet(v, 3), _jet(v, 2), _jet(v, 1));
      }
    }
    return {
      'method': 'cam',
      'stage': stage,
      'target_class': label,
      'image': base64Encode(img.encodePng(resized)),
      'heatmap': base64Encode(img.encodePng(colored)),
    };
  }

  /// Jet colormap channel: 3 = red, 2 = green, 1 = blue
  static int _jet(double v, int center) => (255 * (1.5 - (4 * v - center).abs()).clamp(0.0, 1.0)).round();

  static List<double> _softmax(List<double> logits) {
    final top = logits.reduce((a, b) => math.max(a, b));
    final exps = logits.map((v) => math.exp(v - top)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  static int _argmax(List<double> values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  static List<double> _flatten(Object nested) {
    final out = <double>[];
    void walk(Object o) {
      if (o is List) {
        for (final e in o) {
          walk(e as Object);
        }
      } else {
        out.add((o as num).toDouble());
      }
    }

    walk(nested);
    return out;
  }
}
