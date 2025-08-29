class RockClassification {
  final String rockType;
  final double confidence;
  final String? description;
  final Map<String, dynamic>? additionalData;

  const RockClassification({
    required this.rockType,
    required this.confidence,
    this.description,
    this.additionalData,
  });

  factory RockClassification.fromJson(Map<String, dynamic> json) {
    return RockClassification(
      rockType: json['rockType'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rockType': rockType,
      'confidence': confidence,
      if (description != null) 'description': description,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'RockClassification(rockType: $rockType, confidence: $confidence)';
  }
}
