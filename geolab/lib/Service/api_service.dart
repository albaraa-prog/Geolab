import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dio/dio.dart' hide MultipartFile;
import 'package:dio/dio.dart' as dio_lib show MultipartFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart'; // Add MediaType support
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolab/config/app_config.dart';
import 'package:geolab/constants/auth_constants.dart';
import 'package:geolab/models/feedback_model.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/models/user_model.dart';
import 'package:geolab/Service/network_service.dart';
import 'package:geolab/Service/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Use configuration from AppConfig
  static String get baseUrl => AppConfig.baseUrl;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NetworkService _networkService = NetworkService();

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
        
        // Initialize retry count if not present
        options.extra['retryCount'] = options.extra['retryCount'] ?? 0;



        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by clearing token
        if (error.response?.statusCode == 401) {
          await _deleteToken();
          handler.next(error);
          return;
        }

        // SECURITY FIX: Retry logic for network errors and 5xx errors
        final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
        final maxRetries = AppConfig.maxRetries;
        
        // Check if we should retry
        bool shouldRetry = false;
        
        // Don't retry FormData requests as they finalize the stream
        if (error.requestOptions.data is FormData) {
          shouldRetry = false;
        } else if (retryCount < maxRetries) {
          // Retry on network errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError) {
            shouldRetry = true;
          }
          // Retry on 5xx server errors
          else if (error.response?.statusCode != null &&
                   error.response!.statusCode! >= 500 &&
                   error.response!.statusCode! < 600) {
            shouldRetry = true;
          }
          // Retry on 429 (rate limit) with backoff
          else if (error.response?.statusCode == 429) {
            shouldRetry = true;
          }
        }
        
        if (shouldRetry) {
          // Exponential backoff: 2^retryCount seconds
          final delaySeconds = (1 << retryCount).clamp(1, 10);
          await Future.delayed(Duration(seconds: delaySeconds));
          
          // Increment retry count
          error.requestOptions.extra['retryCount'] = retryCount + 1;
          

          
          try {
            // Retry the request
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // If retry also fails, continue with error handling
            if (e is DioException) {
              error = e;
            }
          }
        }


        handler.next(error);
      },
    ));

    // Add timeout configuration
    _dio.options.receiveTimeout =
        const Duration(seconds: AppConfig.receiveTimeoutSeconds);
    _dio.options.sendTimeout =
        const Duration(seconds: AppConfig.sendTimeoutSeconds);
  }

  // Token management methods (now using Supabase)
  Future<String?> _getToken() async {
    if (!SupabaseService.isInitialized) {
      return null;
    }
    try {
      // Get Supabase session token
      final client = SupabaseService.client;
      if (client == null) {
        return null;
      }
      final session = client.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }
  Future<void> _saveToken(String token) async {
    // Token is automatically managed by Supabase
    // Keep this for backward compatibility
    await _storage.write(key: AuthConstants.tokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    // Supabase handles token deletion on signOut
    await _storage.delete(key: AuthConstants.tokenKey);
  }

  // Check network connectivity before making API calls
  Future<void> _checkConnectivity() async {
    final isConnected = await _networkService.checkConnectivity();
    if (!isConnected) {
      throw Exception('No internet connection. Please check your network settings.');
    }
  }

  

  // Supabase Email Verification (Magic Link) Authentication
  Future<void> sendEmailVerification({
    required String email,
    String? name,
    String? password,
  }) async {
    try {
      await _checkConnectivity();
      // For web, construct redirect URL
      String? redirectTo;
      if (kIsWeb) {
        redirectTo = '${Uri.base.origin}/';
      }
      await SupabaseService.sendEmailVerification(
        email: email,
        redirectTo: redirectTo,
      );
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      await _checkConnectivity();
      
      final response = await _dio.post(
        '$baseUrl/auth/check-email',
        data: {
          'email': email.trim().toLowerCase(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['exists'] == true;
      }
      
      // If we can't check, assume it doesn't exist to allow registration
      return false;
    } catch (e) {

      // If we can't check, assume it doesn't exist to allow registration
      return false;
    }
  }

  // Password-based authentication
  Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _checkConnectivity();
      final authResponse = await SupabaseService.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (authResponse.user != null) {
        final token = authResponse.session?.accessToken;
        if (token != null) {
          await _saveToken(token);
        }
        
        final user = authResponse.user!;
        final userMetadata = user.userMetadata ?? {};
        
        return {
          'access_token': token,
          'user': {
            'id': user.id,
            'email': user.email,
            'subscription_tier': userMetadata['subscription_tier'] ?? 'free',
          },
        };
      }
      
      throw Exception('Login failed');
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _checkConnectivity();
      await SupabaseService.resetPassword(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Login method - supports both password and email verification
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await loginWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {

    } finally {
      await _deleteToken();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return null;
      
      // Get user profile from Supabase
      final userMetadata = user.userMetadata ?? {};
      final subscriptionTier = userMetadata['subscription_tier'] ?? 'free';
      
      // Get daily limit based on subscription tier
      int dailyLimit = 5; // Default for free tier
      if (subscriptionTier == 'premium') {
        dailyLimit = 1000;
      } else if (subscriptionTier == 'enterprise') {
        dailyLimit = 10000;
      }
      
      // Parse DateTime from ISO string format
      final createdAt = DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now();
      final lastLogin = user.lastSignInAt != null 
          ? DateTime.tryParse(user.lastSignInAt.toString())
          : null;
      
      // Get name from user metadata or user metadata
      final name = userMetadata['name'] ?? 
                   userMetadata['full_name'] ?? 
                   userMetadata['fullName'] ??
                   user.userMetadata?['name'];

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: name,
        subscriptionTier: subscriptionTier,
        requestCount: (userMetadata['request_count'] as int?) ?? 0,
        dailyLimit: (userMetadata['daily_limit'] as int?) ?? dailyLimit,
        createdAt: createdAt,
        lastLogin: lastLogin,
      );
    } catch (e) {

      return null;
    }
  }

  // Prediction Methods
  Future<PredictionModel> predictRockType(io.File imageFile) async {
    try {
      await _checkConnectivity();
      
      // SECURITY FIX: Validate image before processing
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSizeBytes) {
        throw Exception(
          'Image size too large. Maximum size: ${AppConfig.maxImageSizeBytes / (1024 * 1024)}MB'
        );
      }
      
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      
      // Validate file extension
      final fileName = imageFile.path.toLowerCase();
      final hasValidExtension = AppConfig.allowedImageTypes.any(
        (ext) => fileName.endsWith('.$ext')
      );
      if (!hasValidExtension) {
        throw Exception(
          'Invalid image type. Allowed types: ${AppConfig.allowedImageTypes.join(", ")}'
        );
      }
      


      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('Authentication required');
      }

      // Upload image to Supabase Storage to get accessible URL
      final imageUrl = await SupabaseService.uploadImage(
        userId: user.id,
        imageFile: imageFile,
      );
      


      // Request prediction from ML backend using the image URL
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.post(
        '$baseUrl/predict',
        data: {
          'image_url': imageUrl,
          'user_id': user.id,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {

            return status! < 500;
          },
        ),
      );



      if (response.statusCode == 200 && response.data != null) {
        try {
          // Backend wraps response in {data: {...}, success: true}
          // Extract the actual prediction data
          final predictionData = response.data['data'] ?? response.data;

          return PredictionModel.fromJson(predictionData);
        } catch (e) {

          throw Exception('Failed to parse prediction result');
        }
      }

      // Handle specific error cases
      if (response.statusCode == 422) {
        final errorMsg = response.data?['error'] ?? 'Image processing failed';
        throw Exception('Classification error: $errorMsg');
      }

      throw Exception(response.data?['error'] ??
          'Prediction failed with status ${response.statusCode}');
    } catch (e) {

      rethrow;
    }
  }

  /// Predict rock type from image bytes (for web)
  Future<PredictionModel> predictRockTypeFromBytes(Uint8List imageBytes, String fileName) async {
    try {
      await _checkConnectivity();
      
      // SECURITY FIX: Validate image bytes before processing
      if (imageBytes.isEmpty) {
        throw Exception('Image data is empty');
      }
      
      // Check file size
      if (imageBytes.length > AppConfig.maxImageSizeBytes) {
        throw Exception(
          'Image size too large. Maximum size: ${AppConfig.maxImageSizeBytes / (1024 * 1024)}MB'
        );
      }
      
      // Validate file extension
      final fileNameLower = fileName.toLowerCase();
      final hasValidExtension = AppConfig.allowedImageTypes.any(
        (ext) => fileNameLower.endsWith('.$ext')
      );
      if (!hasValidExtension) {
        throw Exception(
          'Invalid image type. Allowed types: ${AppConfig.allowedImageTypes.join(", ")}'
        );
      }
      


      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('Authentication required');
      }

      // Upload image bytes to Supabase Storage
      final imageUrl = await SupabaseService.uploadImageBytes(
        userId: user.id,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      


      // Request prediction from ML backend using the uploaded image URL
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.post(
        '$baseUrl/predict',
        data: {
          'image_url': imageUrl,
          'user_id': user.id,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },

        ),
      );



      if (response.statusCode == 200 && response.data != null) {
        try {
          // Backend wraps response in {data: {...}, success: true}
          // Extract the actual prediction data
          final predictionData = response.data['data'] ?? response.data;

          return PredictionModel.fromJson(predictionData);
        } catch (e) {

          throw Exception('Failed to parse prediction result');
        }
      }

      // Handle specific error cases
      if (response.statusCode == 422) {
        final errorMsg = response.data?['error'] ?? 'Image processing failed';
        throw Exception('Classification error: $errorMsg');
      }

      throw Exception(response.data?['error'] ??
          'Prediction failed with status ${response.statusCode}');
    } catch (e) {

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

  Future<List<PredictionModel>> getMyPredictions({int page = 1, int limit = 10}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await _dio.get(
        '$baseUrl/predictions/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
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

  // Build absolute URL for uploaded files served by backend
  String buildFileUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    
    // Normalize the path by converting backslashes to forward slashes and removing leading slashes
    final normalized = relativePath
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    
    // If the path already starts with 'uploads/', use it as is
    // If it doesn't start with 'uploads/', add it
    final finalPath = normalized.startsWith('uploads/') 
        ? normalized 
        : 'uploads/$normalized';
    
    // Backend serves files at /api/uploads/ (keep the /api part)
    final result = '$baseUrl/$finalPath';

    return result;
  }

  // Explain endpoint (Enhanced with actual API call)
  Future<Map<String, dynamic>> explainPrediction({
    io.File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    String? imageUrl,
    required String predictedClass,
    required double confidence,
  }) async {
    try {
      await _checkConnectivity();
      
      // If we don't have an image OR image URL, fallback to simple text
      if (imageFile == null && (imageBytes == null || imageBytes.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) {
         return {
           'explanation': 'Predicted $predictedClass with ${(confidence * 100).toStringAsFixed(1)}% confidence.',
           'xai_visualization': null
         };
      }
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      dynamic requestData;
      
      // Determine if we are sending URL (JSON) or File (FormData)
      if (imageUrl != null && imageUrl.isNotEmpty && imageFile == null && (imageBytes == null || imageBytes.isEmpty)) {
        requestData = {'image_url': imageUrl};
      } else {
        FormData formData;
        
        if (imageBytes != null && kIsWeb) {
          formData = FormData.fromMap({
            'image': dio_lib.MultipartFile.fromBytes(
              imageBytes,
              filename: fileName ?? 'rock_image.jpg',
              contentType: MediaType.parse('image/jpeg'), // Explicit content type for Web
            ),
          });
        } else if (imageFile != null) {
          formData = FormData.fromMap({
            'image': await dio_lib.MultipartFile.fromFile(
              imageFile.path,
              filename: fileName ?? 'rock_image.jpg',
            ),
          });
        } else {
           // Should be unreachable due to first check, but fallback
           return {
             'explanation': 'Predicted $predictedClass with ${(confidence * 100).toStringAsFixed(1)}% confidence.',
             'xai_visualization': null
           };
        }
        requestData = formData;
      }

      final response = await _dio.post(
        '$baseUrl/xai/explain',
        data: requestData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {

        return {
          'explanation': response.data['explanation'] ?? response.data['reasoning'] ?? 'No explanation available.',
          'xai_visualization': response.data['xai_visualization'], // Relative path from backend
          'probabilities': response.data['probabilities'],
          'stage1': response.data['stage1'],
          'stage2': response.data['stage2'],
          'stage3': response.data['stage3'],
          'comparison_stage2': response.data['comparison_stage2'],
          'gradcam': response.data['gradcam'],
        };
      } else {
        // Fallback on API error

        final conf = (confidence * 100).toStringAsFixed(1);
        return {
           'explanation': 'Predicted $predictedClass with $conf% confidence. (Detailed explanation unavailable)',
           'xai_visualization': null
         };
      }
    } catch (e) {

      final conf = (confidence * 100).toStringAsFixed(1);
      return {
          'explanation': 'Predicted $predictedClass with $conf% confidence.',
          'xai_visualization': null
      };
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
    try {
      // First try to get from Supabase (if initialized)
      final user = SupabaseService.currentUser;
      if (user != null) {
        return true;
      }
      // Fallback to checking stored token
      final token = await _storage.read(key: AuthConstants.tokenKey);
      return token != null;
    } catch (e) {
      // If Supabase not initialized, just check stored token
      if (e.toString().contains('not been initialized')) {
        final token = await _storage.read(key: AuthConstants.tokenKey);
        return token != null;
      }
      return false;
    }
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AuthConstants.tokenKey);
  }

  
  // OTP Methods for Email Verification (Backend API versions)
  // Note: These methods call the backend API, while sendOTP() and verifyOTP() above use Supabase directly
  Future<Map<String, dynamic>> sendOTPViaBackend({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/send-otp',
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to send OTP');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> sendSignupOTP({
    required String email,
  }) async {
    try {
      await _checkConnectivity();
      
      final response = await _dio.post(
        '$baseUrl/user/send-signup-otp',
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to send signup OTP');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> resendOTP({
    required String email,
  }) async {
    try {
      await _checkConnectivity();
      
      final response = await _dio.post(
        '$baseUrl/user/resend-otp',
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to resend OTP');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyOTPAndRegister({
    required String email,
    required String name,
    required String password,
    required String otp,
    required String subscriptionTier,
  }) async {
    try {
      await _checkConnectivity();
      
      final response = await _dio.post(
        '$baseUrl/user/verify-otp-register',
        data: {
          'email': email,
          'name': name,
          'password': password,
          'otp': otp,
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

      throw Exception('OTP verification or registration failed');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Alternative method if you want to separate verification from registration (Backend API version)
  // Note: This method calls the backend API, while verifyOTP() above uses Supabase directly
  Future<Map<String, dynamic>> verifyOTPViaBackend({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user/verify-otp',
        data: {
          'email': email,
          'otp_code': otp,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('OTP verification failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Updated register method to support name and email verification
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String subscriptionTier = 'free',
    bool isEmailVerified = false,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'subscription_tier': subscriptionTier,
        'is_email_verified': isEmailVerified,
      };

      // Only add name if provided
      if (name != null && name.isNotEmpty) {
        requestData['name'] = name;
      }

      final response = await _dio.post(
        '$baseUrl/user/register',
        data: requestData,
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

  // Test connection method
  Future<bool> testConnection() async {
    try {
      // First check if device has internet connectivity
      final isConnected = await _networkService.checkConnectivity();
      if (!isConnected) {
        // No internet connection available
        return false;
      }

      // Then test if we can reach the API server
      final response = await _dio.get(
        AppConfig.getUrl(AppConfig.healthEndpoint),
        options: Options(
          sendTimeout: AppConfig.getTimeout('health_check'),
          receiveTimeout: AppConfig.getTimeout('health_check'),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      // Connection test failed
    }
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

