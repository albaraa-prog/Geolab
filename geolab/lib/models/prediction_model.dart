import 'package:json_annotation/json_annotation.dart';

part 'prediction_model.g.dart';

@JsonSerializable()
class PredictionModel {
  final String prediction;
  final double confidence;
  final String? id;
  final String? xaiVisualization;
  final String? imagePath;
  final Map<String, double> probabilities;
  final Map<String, double> confidenceBreakdown;
  final String? reasoning;
  final Map<String, dynamic>? stage1;
  final Map<String, dynamic>? stage2;
  final Map<String, dynamic>? stage3;
  final DateTime timestamp;

  PredictionModel({
    required this.prediction,
    required this.confidence,
    this.id,
    this.xaiVisualization,
    this.imagePath,
    this.probabilities = const {},
    this.confidenceBreakdown = const {},
    this.reasoning,
    this.stage1,
    this.stage2,
    this.stage3,
    required this.timestamp,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    var metadata = json['metadata'] ?? {};
    
    // Parse helper for stages
    Map<String, dynamic>? parseStage(dynamic stageData) {
      if (stageData == null) return null;
      if (stageData is Map) return Map<String, dynamic>.from(stageData);
      return null;
    }

    return PredictionModel(
      prediction: json['classification'] ?? json['class'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      id: json['prediction_id'] ?? json['id'],
      xaiVisualization: json['xai_visualization'] ?? metadata['xai_visualization'],
      imagePath: json['image_url'] ?? json['image_path'],
      probabilities: (json['probabilities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          (metadata['probabilities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ?? 
          {},
      confidenceBreakdown: (json['confidence_breakdown'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      reasoning: json['reasoning'] ?? json['explanation'] ?? (metadata['reasoning']),
      stage1: parseStage(json['stage1'] ?? metadata['stage1']),
      stage2: parseStage(json['stage2'] ?? metadata['stage2']),
      stage3: parseStage(json['stage3'] ?? metadata['stage3']),
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
    Map<String, double>? probabilities,
    Map<String, double>? confidenceBreakdown,
    String? reasoning,
    DateTime? timestamp,
  }) {
    return PredictionModel(
      prediction: prediction ?? this.prediction,
      confidence: confidence ?? this.confidence,
      id: id ?? this.id,
      xaiVisualization: xaiVisualization ?? this.xaiVisualization,
      imagePath: imagePath ?? this.imagePath,
      probabilities: probabilities ?? this.probabilities,
      confidenceBreakdown: confidenceBreakdown ?? this.confidenceBreakdown,
      reasoning: reasoning ?? this.reasoning,
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
