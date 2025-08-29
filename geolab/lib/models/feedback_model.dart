import 'package:json_annotation/json_annotation.dart';

part 'feedback_model.g.dart';

@JsonSerializable()
class FeedbackModel {
  final String id;
  final String predictionId;
  final String userId;
  final bool isCorrect;
  final String? userComment;
  final DateTime timestamp;

  FeedbackModel({
    required this.id,
    required this.predictionId,
    required this.userId,
    required this.isCorrect,
    this.userComment,
    required this.timestamp,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackModelToJson(this);

  bool get hasComment => userComment != null && userComment!.isNotEmpty;

  FeedbackModel copyWith({
    String? id,
    String? predictionId,
    String? userId,
    bool? isCorrect,
    String? userComment,
    DateTime? timestamp,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      predictionId: predictionId ?? this.predictionId,
      userId: userId ?? this.userId,
      isCorrect: isCorrect ?? this.isCorrect,
      userComment: userComment ?? this.userComment,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'FeedbackModel(id: $id, isCorrect: $isCorrect, hasComment: $hasComment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
