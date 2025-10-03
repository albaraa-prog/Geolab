class AppConfig {
  // Backend configuration
  // For Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // For Windows desktop/web testing
  // static const String baseUrl = 'http://localhost:8000/api';

  // For physical device testing, change this to your PC's IP address
  // static const String baseUrl = 'http://192.168.1.100:8000/api';

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
