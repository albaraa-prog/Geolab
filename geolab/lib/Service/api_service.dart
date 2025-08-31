import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolab/config/app_config.dart';
import 'package:geolab/constants/auth_constants.dart';
import 'package:geolab/models/feedback_model.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/models/user_model.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiService {
  // Use configuration from AppConfig
  static const String baseUrl = AppConfig.baseUrl;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();

    // Request interceptor to add authentication token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from secure storage
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Add common headers
        options.headers['Accept'] = 'application/json';
        options.headers['Content-Type'] = 'application/json';

        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by clearing token and redirecting to login
        if (error.response?.statusCode == 401) {
          await _deleteToken();
        }

        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));

    // Add timeout configuration
    _dio.options.receiveTimeout =
        const Duration(seconds: AppConfig.receiveTimeoutSeconds);
    _dio.options.sendTimeout =
        const Duration(seconds: AppConfig.sendTimeoutSeconds);
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
        if (token != null) {
          await _saveToken(token);
        }
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
        if (token != null) {
          await _saveToken(token);
        }
        return response.data;
      }

      throw Exception('Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _dio.post(
          '$baseUrl/user/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API call failed: $e');
    } finally {
      await _deleteToken();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '$baseUrl/user/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _deleteToken();
      }
      return null;
    }
  }

  // Prediction Methods
  Future<PredictionModel> predictRockType(File imageFile) async {
    try {
      print('Sending image: ${imageFile.path}');

      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

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
            'Authorization': 'Bearer $token',
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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/predictions/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.post(
        '$baseUrl/feedback/submit',
        data: {
          'prediction_id': predictionId,
          'is_correct': isCorrect,
          'user_comment': userComment ?? '',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/feedback/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/subscription/status',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.post(
        '$baseUrl/subscription/upgrade',
        data: {
          'subscription_tier': newTier,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/subscription/usage',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/subscription/plans',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/analytics/performance',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/feedback/analytics',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

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

  // Test connection method
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        AppConfig.getUrl(AppConfig.healthEndpoint),
        options: Options(
          sendTimeout: AppConfig.getTimeout('health_check'),
          receiveTimeout: AppConfig.getTimeout('health_check'),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Single error handler at the end of the class
  String _handleDioError(DioException error) {
    if (error.response?.data != null) {
      final errorData = error.response!.data;
      if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
        return errorData['error'];
      }
      if (errorData is Map<String, dynamic> &&
          errorData.containsKey('message')) {
        return errorData['message'];
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
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        if (error.type == DioExceptionType.connectionTimeout) {
          return 'Connection timeout. Please check your internet connection.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          return 'Request timeout. Please try again.';
        } else if (error.type == DioExceptionType.connectionError) {
          return 'Connection error. Please check your internet connection.';
        }
        return 'Network error. Please check your connection.';
    }
  }
} // End of class
