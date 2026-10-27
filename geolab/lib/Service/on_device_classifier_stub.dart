import 'dart:typed_data';

/// Web stub: on-device inference is not available.
class OnDeviceClassifier {
  static Future<OnDeviceClassifier?> load() async => null;

  Future<Map<String, dynamic>> classify(Uint8List imageBytes) =>
      throw UnsupportedError('On-device classification is not available on this platform');
}
