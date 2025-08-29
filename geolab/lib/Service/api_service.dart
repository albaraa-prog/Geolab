import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolab/constants/auth_constants.dart';
import 'package:geolab/models/feedback_model.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/models/user_model.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiService {
  // Use your PC's IP address for device/emulator testing
  // For Android emulator: use 10.0.2.2 instead of localhost
  static const String baseUrl =
      'http://10.0.2.2:8000/api'; // Changed for emulator testing

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.clear(); // Clear existing interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Bypass authentication for testing
        options.headers['Authorization'] = 'Bearer test_token';

        // Add common headers
        options.headers['Accept'] = 'application/json';
        options.headers['Content-Type'] = 'application/json';

        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}'); // Add logging for debugging
        handler.next(error);
      },
    ));
  }

  // Token management methods
  Future<String?> _getToken() async {
    return await _storage.read(key: AuthConstants.tokenKey);
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: AuthConstants.tokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    await _storage.delete(key: AuthConstants.tokenKey);
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String subscriptionTier = 'free',
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/register',
        data: {
          'email': email,
          'password': password,
          'subscription_tier': subscriptionTier,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['access_token'];
        await _storage.write(key: AuthConstants.tokenKey, value: token);
        return response.data;
      }

      throw Exception('Registration failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        await _storage.write(key: AuthConstants.tokenKey, value: token);
        return response.data;
      }

      throw Exception('Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('$baseUrl/user/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _storage.delete(key: AuthConstants.tokenKey);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get('$baseUrl/user/profile');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: AuthConstants.tokenKey);
      }
      return null;
    }
  }

  // Prediction Methods
  Future<PredictionModel> predictRockType(File imageFile) async {
    try {
      print('Sending image: ${imageFile.path}');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      print('FormData created');

      final response = await _dio.post(
        '$baseUrl/predict',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            print('Response status: $status');
            return status! < 500;
          },
        ),
      );

      print('Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        try {
          return PredictionModel.fromJson(response.data);
        } catch (e) {
          print('Error parsing response: $e');
          print('Response data: ${response.data}');
          throw Exception('Failed to parse prediction result');
        }
      }

      throw Exception(response.data?['error'] ??
          'Prediction failed with status ${response.statusCode}');
    } catch (e) {
      print('Error in predictRockType: $e');
      rethrow;
    }
  }

  Future<List<PredictionModel>> getUserPredictions(String userId) async {
    try {
      final response = await _dio.get('$baseUrl/predictions/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> predictions = response.data['predictions'];
        return predictions
            .map((json) => PredictionModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Feedback Methods
  Future<FeedbackModel> submitFeedback({
    required String predictionId,
    required bool isCorrect,
    String? userComment,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/feedback/submit',
        data: {
          'prediction_id': predictionId,
          'is_correct': isCorrect,
          'user_comment': userComment ?? '',
        },
      );

      if (response.statusCode == 201) {
        return FeedbackModel.fromJson(response.data);
      }

      throw Exception('Feedback submission failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FeedbackModel>> getUserFeedback(String userId) async {
    try {
      final response = await _dio.get('$baseUrl/feedback/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> feedback = response.data['feedback'];
        return feedback.map((json) => FeedbackModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Subscription Methods
  Future<SubscriptionModel> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('$baseUrl/subscription/status');

      if (response.statusCode == 200) {
        return SubscriptionModel.fromJson(response.data);
      }

      throw Exception('Failed to get subscription status');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> upgradeSubscription(String newTier) async {
    try {
      final response = await _dio.post(
        '$baseUrl/subscription/upgrade',
        data: {
          'subscription_tier': newTier,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Subscription upgrade failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final response = await _dio.get('$baseUrl/subscription/usage');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to get usage statistics');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('$baseUrl/subscription/plans');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to get subscription plans');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Analytics Methods (Enterprise only)
  Future<Map<String, dynamic>> getPerformanceAnalytics() async {
    try {
      final response = await _dio.get('$baseUrl/analytics/performance');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to get performance analytics');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getFeedbackAnalytics() async {
    try {
      final response = await _dio.get('$baseUrl/feedback/analytics');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to get feedback analytics');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Utility Methods
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AuthConstants.tokenKey);
    return token != null;
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AuthConstants.tokenKey);
  }

  // Single error handler at the end of the class
  String _handleDioError(DioException error) {
    if (error.response?.data != null) {
      final errorData = error.response!.data;
      if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
        return errorData['error'];
      }
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Unprocessable Entity. Please check the data you\'ve provided.';
      case 429:
        return 'Rate limit exceeded. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Network error. Please check your connection.';
    }
  }
} // End of class
