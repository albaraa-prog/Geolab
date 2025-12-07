import 'dart:io' as io;
import 'dart:typed_data';

import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/models/rock_model.dart';

abstract class RockClassificationService {
  Future<RockClassification> classifyRock(io.File image);
  Future<RockClassification> classifyRockFromBytes(Uint8List imageBytes, String fileName);
}

class RockClassificationServiceImpl implements RockClassificationService {
  final ApiService _apiService = ApiService();

  @override
  Future<RockClassification> classifyRock(io.File image) async {
    try {
      // Validate image size before sending
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception(
            'Image size too large. Please use an image under 10MB.');
      }

      final PredictionModel prediction =
          await _apiService.predictRockType(image);

      // Removed overly strict validation - parsing already handles defaults
      print('Parsed prediction: ${prediction.prediction}, confidence: ${prediction.confidence}');


      return RockClassification(
        rockType: prediction.prediction,
        confidence: prediction.confidence,
        additionalData: {
          'prediction_id': prediction.id,
          'xai_visualization': prediction.xaiVisualization,
          'timestamp': prediction.timestamp.toIso8601String(),
          'image_url': prediction.imagePath,
          'stage1': prediction.stage1,
          'stage2': prediction.stage2,
          'stage3': prediction.stage3,
          'probabilities': prediction.probabilities,
          'reasoning': prediction.reasoning,
        },
      );
    } catch (e) {
      print('Rock classification service error: $e');
      if (e.toString().contains('422') || e.toString().contains('Image processing failed')) {
        throw Exception('Image processing failed: ${e.toString()}');
      }
      throw Exception('Classification failed: ${e.toString()}');
    }
  }

  @override
  Future<RockClassification> classifyRockFromBytes(Uint8List imageBytes, String fileName) async {
    try {
      // Validate image size before sending
      if (imageBytes.length > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception(
            'Image size too large. Please use an image under 10MB.');
      }

      final PredictionModel prediction =
          await _apiService.predictRockTypeFromBytes(imageBytes, fileName);

      // Removed overly strict validation - parsing already handles defaults
      print('Parsed prediction: ${prediction.prediction}, confidence: ${prediction.confidence}');


      return RockClassification(
        rockType: prediction.prediction,
        confidence: prediction.confidence,
        additionalData: {
          'prediction_id': prediction.id,
          'xai_visualization': prediction.xaiVisualization,
          'timestamp': prediction.timestamp.toIso8601String(),
          'image_url': prediction.imagePath,
          'stage1': prediction.stage1,
          'stage2': prediction.stage2,
          'stage3': prediction.stage3,
          'probabilities': prediction.probabilities,
          'reasoning': prediction.reasoning,
        },
      );
    } catch (e) {
      print('Rock classification service error: $e');
      if (e.toString().contains('422') || e.toString().contains('Image processing failed')) {
        throw Exception('Image processing failed: ${e.toString()}');
      }
      throw Exception('Classification failed: ${e.toString()}');
    }
  }
}
