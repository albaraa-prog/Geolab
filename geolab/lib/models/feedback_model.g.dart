// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      id: json['id'] as String,
      predictionId: json['predictionId'] as String,
      userId: json['userId'] as String,
      isCorrect: json['isCorrect'] as bool,
      userComment: json['userComment'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'predictionId': instance.predictionId,
      'userId': instance.userId,
      'isCorrect': instance.isCorrect,
      'userComment': instance.userComment,
      'timestamp': instance.timestamp.toIso8601String(),
    };
