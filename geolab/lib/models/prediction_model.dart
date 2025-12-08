import 'dart:convert';
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
    
    // Robust helper to parse Maps from either Map object or JSON String
    Map<String, dynamic>? parseMap(dynamic input) {
      if (input == null) return null;
      if (input is Map) return Map<String, dynamic>.from(input);
      if (input is String) {
        try {
          final decoded = jsonDecode(input);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (e) {
          // Error parsing JSON string
        }
      }
      return null;
    }

    // Helper to parse probabilities specifically to Map<String, double>
    Map<String, double> parseProbs(dynamic input) {
      final map = parseMap(input);
      if (map == null) return {};
      try {
        return map.map((k, v) {
          if (v is num) return MapEntry(k, v.toDouble());
          if (v is String) return MapEntry(k, double.tryParse(v) ?? 0.0);
          return MapEntry(k, 0.0);
        });
      } catch (e) {
        return {};
      }
    }

    // Attempt to find probabilities in multiple locations
    final probs = parseProbs(json['probabilities']) 
             ..addAll(parseProbs(metadata['probabilities']));

    return PredictionModel(
      prediction: json['classification'] ?? json['class'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      id: json['prediction_id'] ?? json['id'],
      xaiVisualization: json['xai_visualization'] ?? metadata['xai_visualization'],
      imagePath: json['image_url'] ?? json['image_path'],
      probabilities: probs.isNotEmpty ? probs : {},
      confidenceBreakdown: parseProbs(json['confidence_breakdown']),
      reasoning: json['reasoning'] ?? json['explanation'] ?? (metadata['reasoning']),
      stage1: parseMap(json['stage1'] ?? metadata['stage1']),
      stage2: parseMap(json['stage2'] ?? metadata['stage2']),
      stage3: parseMap(json['stage3'] ?? metadata['stage3']),
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
