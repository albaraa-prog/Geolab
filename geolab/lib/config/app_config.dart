import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase configuration - loaded from .env file
  static String get supabaseUrl {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      if (url == null || url.isEmpty || url == 'YOUR_SUPABASE_URL') {
        print('⚠ WARNING: SUPABASE_URL is not configured in .env file');
        throw Exception(
          'SUPABASE_URL is not configured. Please create a .env file in the geolab directory with:\n'
          'SUPABASE_URL=https://your-project.supabase.co\n'
          'SUPABASE_ANON_KEY=your-anon-key\n\n'
          'Get your keys from: https://app.supabase.com → Your Project → Settings → API'
        );
      }
      return url;
    } catch (e) {
      print('⚠ ERROR getting SUPABASE_URL: $e');
      rethrow;
    }
  }
  
  static String get supabaseAnonKey {
    try {
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      if (key == null || key.isEmpty || key == 'YOUR_SUPABASE_ANON_KEY') {
        print('⚠ WARNING: SUPABASE_ANON_KEY is not configured in .env file');
        throw Exception(
          'SUPABASE_ANON_KEY is not configured. Please create a .env file in the geolab directory with:\n'
          'SUPABASE_URL=https://your-project.supabase.co\n'
          'SUPABASE_ANON_KEY=your-anon-key\n\n'
          'Get your keys from: https://app.supabase.com → Your Project → Settings → API'
        );
      }
      return key;
    } catch (e) {
      print('⚠ ERROR getting SUPABASE_ANON_KEY: $e');
      rethrow;
    }
  }
  
  // Backend configuration (Flask API for ML predictions)
  // Can be configured via .env file with FLASK_API_URL
  // Default to localhost for Windows/Web/Desktop platforms
  // For Android emulator, change to: 'http://10.0.2.2:8000/api'
  // For physical Android/iOS device, use your PC's IP address: 'http://192.168.1.XXX:8000/api'
  // For web, use: 'http://localhost:8000/api' (ensure Flask is running and CORS is configured)
  static String get baseUrl {
    try {
      final url = dotenv.env['FLASK_API_URL'];
      if (url != null && url.isNotEmpty && url != 'YOUR_FLASK_API_URL') {
        return url.endsWith('/api') ? url : '$url/api';
      }
    } catch (e) {
      print('⚠ WARNING: Could not read FLASK_API_URL from .env: $e');
    }
    // Default fallback
    return 'http://localhost:8000/api';
  }

  // API endpoints
  static const String healthEndpoint = '/health';
  static const String authEndpoint = '/user';
  static const String predictEndpoint = '/predict';
  static const String feedbackEndpoint = '/feedback';
  static const String subscriptionEndpoint = '/subscription';
  static const String analyticsEndpoint = '/analytics';

  // Timeout configurations
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  static const int sendTimeoutSeconds = 30;

  // File upload configurations
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Rate limiting
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache configurations
  static const Duration tokenCacheDuration = Duration(days: 7);
  static const Duration predictionCacheDuration = Duration(hours: 24);

  // Feature flags
  static const bool enableOfflineMode = false;
  static const bool enableImageCompression = true;
  static const bool enableAnalytics = true;

  // Debug configurations
  static const bool enableApiLogging = true;
  static const bool enableNetworkLogging = true;

  // Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Check if running in debug mode
  static bool get isDebugMode {
    // In a real app, you might want to check this differently
    return true;
  }

  // Get appropriate timeout for different operations
  static Duration getTimeout(String operation) {
    switch (operation) {
      case 'health_check':
        return const Duration(seconds: 5);
      case 'image_upload':
        return const Duration(seconds: 60);
      case 'prediction':
        return const Duration(seconds: 30);
      default:
        return const Duration(seconds: 30);
    }
  }
}
