// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PredictionModel _$PredictionModelFromJson(Map<String, dynamic> json) =>
    PredictionModel(
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      id: json['id'] as String?,
      xaiVisualization: json['xaiVisualization'] as String?,
      imagePath: json['imagePath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$PredictionModelToJson(PredictionModel instance) =>
    <String, dynamic>{
      'prediction': instance.prediction,
      'confidence': instance.confidence,
      'id': instance.id,
      'xaiVisualization': instance.xaiVisualization,
      'imagePath': instance.imagePath,
      'timestamp': instance.timestamp.toIso8601String(),
    };
