import 'package:json_annotation/json_annotation.dart';

part 'prediction_model.g.dart';

@JsonSerializable()
class PredictionModel {
  final String prediction;
  final double confidence;
  final String? id;
  final String? xaiVisualization;
  final String? imagePath;
  final DateTime timestamp;

  PredictionModel({
    required this.prediction,
    required this.confidence,
    this.id,
    this.xaiVisualization,
    this.imagePath,
    required this.timestamp,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      prediction: json['classification'] ?? json['class'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      id: json['prediction_id'] ?? json['id'],
      xaiVisualization: json['xai_visualization'],
      imagePath: json['image_url'] ?? json['image_path'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$PredictionModelToJson(this);

  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';
  bool get hasXaiVisualization =>
      xaiVisualization != null && xaiVisualization!.isNotEmpty;

  PredictionModel copyWith({
    String? prediction,
    double? confidence,
    String? id,
    String? xaiVisualization,
    String? imagePath,
    DateTime? timestamp,
  }) {
    return PredictionModel(
      prediction: prediction ?? this.prediction,
      confidence: confidence ?? this.confidence,
      id: id ?? this.id,
      xaiVisualization: xaiVisualization ?? this.xaiVisualization,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'PredictionModel(id: $id, prediction: $prediction, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
