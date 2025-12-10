import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolab/config/app_config.dart';

class SupabaseService {
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;
  
  static SupabaseClient? get clientOrNull {
    if (!_isInitialized) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }
  
  static SupabaseClient? get client {
    if (!_isInitialized) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }
  
  // Initialize Supabase (call this in main.dart)
  static Future<void> initialize() async {
    try {
      final url = AppConfig.supabaseUrl;
      final anonKey = AppConfig.supabaseAnonKey;
      
      // Validate URL format
      if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
        throw Exception(
          'Invalid SUPABASE_URL format. Expected: https://your-project.supabase.co\n'
          'Got: $url'
        );
      }
      
      // Validate key format (anon keys are typically long JWT tokens)
      if (anonKey.length < 100) {
        throw Exception(
          'Invalid SUPABASE_ANON_KEY format. The key appears to be too short.\n'
          'Please verify you copied the full "anon/public" key from Supabase dashboard.'
        );
      }
      
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      // Verify initialization was successful by trying to access the client
      try {
        // Access the client to verify initialization
        final _ = Supabase.instance.client;
        _isInitialized = true;
        _isInitialized = true;
      } catch (e) {
        throw Exception(
          'Supabase.initialize() completed but client is not accessible: $e'
        );
      }
    } catch (e) {
      if (e.toString().contains('Invalid') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception(
        'Failed to initialize Supabase: $e\n\n'
        'Please check:\n'
        '1. Your .env file exists in geolab/.env\n'
        '2. SUPABASE_URL and SUPABASE_ANON_KEY are correct\n'
        '3. Get your keys from: https://app.supabase.com → Settings → API'
      );
    }
  }
  
  // ============================================
  // AUTHENTICATION - Email Verification (Magic Link) & Password
  // ============================================
  
  /// Send email verification link (magic link) for sign in/sign up
  /// When user clicks the link in their email, they are automatically verified and signed in
  static Future<void> sendEmailVerification({
    required String email,
    String? redirectTo,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Please check your .env file with SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available. Please check your configuration.');
    }
    
    // For web, construct the redirect URL
    String? finalRedirectTo = redirectTo;
    if (finalRedirectTo == null && kIsWeb) {
      // Use current origin + target path
      finalRedirectTo = '${Uri.base.origin}/';
    }
    
    await clientInstance.auth.signInWithOtp(
      email: email,
      emailRedirectTo: finalRedirectTo,
    );
  }

  /// Sign in with email and password
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Please check your .env file with SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available. Please check your configuration.');
    }
    return await clientInstance.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Please check your .env file with SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available. Please check your configuration.');
    }
    return await clientInstance.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Reset password - sends password reset email
  static Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Please check your .env file with SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available. Please check your configuration.');
    }
    
    // For web, construct the redirect URL to reset password page
    String? finalRedirectTo = redirectTo;
    if (finalRedirectTo == null && kIsWeb) {
      finalRedirectTo = '${Uri.base.origin}/reset-password';
    } else if (finalRedirectTo == null) {
      // For mobile, use deep link
      finalRedirectTo = 'geolab://reset-password';
    }
    
    await clientInstance.auth.resetPasswordForEmail(
      email,
      redirectTo: finalRedirectTo,
    );
  }

  /// Update user profile (email and metadata like name)
  static Future<UserResponse> updateUserProfile({
    String? email,
    String? name,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Please check your .env file.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available.');
    }

    final attributes = UserAttributes(
      email: email,
      data: name != null ? {'name': name} : null,
    );

    return await clientInstance.auth.updateUser(attributes);
  }
  
  /// Get current user
  static User? get currentUser {
    if (!_isInitialized) {
      return null;
    }
    try {
      final clientInstance = clientOrNull;
      if (clientInstance == null) {
        return null;
      }
      return clientInstance.auth.currentUser;
    } catch (e) {
      return null;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    if (!_isInitialized) {
      return; // Nothing to sign out from
    }
    try {
      final clientInstance = client;
      if (clientInstance != null) {
        await clientInstance.auth.signOut();
      }
    } catch (e) {

    }
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Cannot listen to auth state changes.');
    }
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase client is not available.');
    }
    return clientInstance.auth.onAuthStateChange;
  }
  
  // ============================================
  // STORAGE - Image Upload
  // ============================================
  
  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImage({
    required String userId,
    required io.File imageFile,
    String? customFileName,
  }) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized. Cannot upload image.');
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = customFileName ?? 
        '${timestamp}_${imageFile.path.split('/').last}';
    final path = '$userId/$fileName';
    
    // Upload to Supabase Storage
    await clientInstance.storage
        .from('rock-images')
        .upload(path, imageFile, fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ));
    
    // Get public URL
    final publicUrl = clientInstance.storage
        .from('rock-images')
        .getPublicUrl(path);
    
    return publicUrl;
  }

  /// Upload image bytes to Supabase Storage (for web)
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImageBytes({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
    String? contentType,
  }) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized. Cannot upload image.');
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final finalFileName = '${timestamp}_$fileName';
    final path = '$userId/$finalFileName';
    
    // Upload to Supabase Storage
    // Convert Uint8List to List<int> for Supabase storage upload
    await clientInstance.storage
        .from('rock-images')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType ?? 'image/jpeg',
          ),
        );
    
    // Get public URL
    final publicUrl = clientInstance.storage
        .from('rock-images')
        .getPublicUrl(path);
    
    return publicUrl;
  }
  
  /// Delete image from Supabase Storage
  static Future<void> deleteImage(String imageUrl) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized. Cannot delete image.');
    }
    
    // Extract path from URL
    final uri = Uri.parse(imageUrl);
    final path = uri.path.split('/storage/v1/object/public/rock-images/').last;
    
    await clientInstance.storage
        .from('rock-images')
        .remove([path]);
  }
  
  // ============================================
  // DATABASE - Classifications
  // ============================================
  
  /// Get user's classification history
  static Future<List<Map<String, dynamic>>> getClassifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized.');
    }
    
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await clientInstance
        .from('classifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get single classification by ID
  static Future<Map<String, dynamic>?> getClassification(String id) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized.');
    }
    
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await clientInstance
        .from('classifications')
        .select()
        .eq('id', id)
        .eq('user_id', user.id)
        .single();
    
    return response;
  }
  
  // ============================================
  // FEEDBACK
  // ============================================
  
  /// Submit feedback for a prediction
  static Future<Map<String, dynamic>> submitFeedback({
    required String predictionId,
    required bool isCorrect,
    String? comment,
  }) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized.');
    }
    
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await clientInstance
        .from('feedback')
        .insert({
          'prediction_id': predictionId,
          'user_id': user.id,
          'is_correct': isCorrect,
          'user_comment': comment,
        })
        .select()
        .single();
    
    return response;
  }
  
  /// Get user's feedback history
  static Future<List<Map<String, dynamic>>> getFeedbackHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final clientInstance = client;
    if (clientInstance == null) {
      throw Exception('Supabase is not initialized.');
    }
    
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final response = await clientInstance
        .from('feedback')
        .select('*, classifications(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }
}

