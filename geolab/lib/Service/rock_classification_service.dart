import 'dart:io' as io;

import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/models/rock_model.dart';

abstract class RockClassificationService {
  Future<RockClassification> classifyRock(io.File image);
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

      if (prediction.confidence == 0.0 || prediction.prediction.isEmpty) {
        throw Exception('Invalid prediction result');
      }

      return RockClassification(
        rockType: prediction.prediction,
        confidence: prediction.confidence,
        additionalData: {
          'prediction_id': prediction.id,
          'xai_visualization': prediction.xaiVisualization,
          'timestamp': prediction.timestamp.toIso8601String(),
          'image_path': prediction.imagePath,
        },
      );
    } catch (e) {
      throw Exception('Classification failed: ${e.toString()}');
    }
  }
}
