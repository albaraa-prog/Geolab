import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/feedback_model.dart';
import 'package:geolab/models/prediction_model.dart';

class FeedbackService {
  final ApiService _apiService;

  FeedbackService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Submit feedback for a prediction
  Future<FeedbackModel> submitFeedback({
    required String predictionId,
    required bool isCorrect,
    String? userComment,
  }) async {
    try {
      return await _apiService.submitFeedback(
        predictionId: predictionId,
        isCorrect: isCorrect,
        userComment: userComment,
      );
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Get feedback history for a user
  Future<List<FeedbackModel>> getUserFeedback(String userId) async {
    try {
      return await _apiService.getUserFeedback(userId);
    } catch (e) {
      throw Exception('Failed to get user feedback: $e');
    }
  }

  /// Get feedback analytics (Enterprise users only)
  Future<Map<String, dynamic>> getFeedbackAnalytics() async {
    try {
      return await _apiService.getFeedbackAnalytics();
    } catch (e) {
      throw Exception('Failed to get feedback analytics: $e');
    }
  }

  /// Create feedback from prediction result
  FeedbackModel createFeedbackFromPrediction({
    required PredictionModel prediction,
    required bool isCorrect,
    String? userComment,
  }) {
    return FeedbackModel(
      id: '', // Will be set by backend
      predictionId: prediction.id ?? '',
      userId: '', // Will be set by backend
      isCorrect: isCorrect,
      userComment: userComment,
      timestamp: DateTime.now(),
    );
  }

  /// Validate feedback data
  bool validateFeedback({
    required String predictionId,
    required bool isCorrect,
    String? userComment,
  }) {
    if (predictionId.isEmpty) return false;
    if (userComment != null && userComment.length > 1000) return false;
    return true;
  }

  /// Get feedback statistics
  Map<String, dynamic> getFeedbackStats(List<FeedbackModel> feedbackList) {
    if (feedbackList.isEmpty) {
      return {
        'total': 0,
        'correct': 0,
        'incorrect': 0,
        'accuracy': 0.0,
        'withComments': 0,
      };
    }

    final total = feedbackList.length;
    final correct = feedbackList.where((f) => f.isCorrect).length;
    final incorrect = total - correct;
    final accuracy = total > 0 ? (correct / total) * 100 : 0.0;
    final withComments = feedbackList.where((f) => f.hasComment).length;

    return {
      'total': total,
      'correct': correct,
      'incorrect': incorrect,
      'accuracy': accuracy,
      'withComments': withComments,
    };
  }
}
