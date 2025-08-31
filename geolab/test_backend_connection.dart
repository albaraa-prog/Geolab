import 'package:geolab/Service/api_service.dart';
import 'package:geolab/config/app_config.dart';

/// Simple test script to verify backend connection
/// Run with: dart test_backend_connection.dart
void main() async {
  print('🧪 Testing Geolab Backend Connection...\n');

  final apiService = ApiService();

  // Test 1: Connection test
  print('1. Testing backend connectivity...');
  try {
    final isConnected = await apiService.testConnection();
    if (isConnected) {
      print('✅ Backend is accessible at ${AppConfig.baseUrl}');
    } else {
      print('❌ Backend is not accessible');
      print('   Please check if the backend server is running');
      print('   Current URL: ${AppConfig.baseUrl}');
      return;
    }
  } catch (e) {
    print('❌ Connection test failed: $e');
    return;
  }

  // Test 2: Configuration validation
  print('\n2. Validating configuration...');
  print('   Base URL: ${AppConfig.baseUrl}');
  print('   Health endpoint: ${AppConfig.getUrl(AppConfig.healthEndpoint)}');
  print('   Auth endpoint: ${AppConfig.getUrl(AppConfig.authEndpoint)}');
  print('   Predict endpoint: ${AppConfig.getUrl(AppConfig.predictEndpoint)}');

  // Test 3: API service initialization
  print('\n3. Testing API service...');
  try {
    final isAuthenticated = await apiService.isAuthenticated();
    print(
        '   Authentication status: ${isAuthenticated ? "Authenticated" : "Not authenticated"}');

    if (isAuthenticated) {
      final user = await apiService.getCurrentUser();
      if (user != null) {
        print('   Current user: ${user.email}');
        print('   Subscription: ${user.subscriptionTier}');
        print('   Requests used: ${user.requestCount}/${user.dailyLimit}');
      }
    }
  } catch (e) {
    print('   ❌ API service test failed: $e');
  }

  // Test 4: Network configuration
  print('\n4. Network configuration check...');
  print('   For Android Emulator: Use 10.0.2.2:8000');
  print('   For Physical Device: Use your PC IP address');
  print('   Current configuration: ${AppConfig.baseUrl}');

  // Test 5: Recommendations
  print('\n5. Setup recommendations...');
  if (AppConfig.baseUrl.contains('10.0.2.2')) {
    print('   ✅ Using Android emulator configuration');
    print('   ℹ️  If testing on physical device, update app_config.dart');
  } else if (AppConfig.baseUrl.contains('localhost') ||
      AppConfig.baseUrl.contains('127.0.0.1')) {
    print('   ⚠️  Using localhost - this may not work on physical devices');
    print('   ℹ️  Update to use your PC IP address for device testing');
  } else {
    print('   ✅ Using custom IP configuration');
  }

  print('\n🎯 Next Steps:');
  print('   1. Ensure backend server is running on port 8000');
  print('   2. Update app_config.dart if using physical device');
  print('   3. Run the Flutter app: flutter run');
  print('   4. Test authentication and rock classification');

  print('\n📚 For more information, see FLUTTER_SETUP_README.md');
}
