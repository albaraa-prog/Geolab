# Geolab Flutter App - Backend Communication Setup

This document provides comprehensive instructions for setting up the Geolab Flutter app to communicate with the backend API.

## 🚀 Quick Start

### Prerequisites

- Flutter 3.0+ installed
- Backend API server running (see main README.md)
- Android Studio / VS Code with Flutter extensions
- Android emulator or physical device

### 1. Clone and Setup

```bash
# Navigate to the Flutter app directory
cd geolab/geolab

# Install dependencies
flutter pub get

# Generate model files (if needed)
flutter packages pub run build_runner build

# Run the app
flutter run
```

## 🔧 Configuration

### Backend URL Configuration

The app is configured to connect to the backend API. You need to update the URL based on your setup:

#### For Android Emulator:

```dart
// In lib/config/app_config.dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

#### For Physical Device:

```dart
// In lib/config/app_config.dart
static const String baseUrl = 'http://YOUR_PC_IP_ADDRESS:8000/api';
```

**To find your PC's IP address:**

- **Windows**: Run `ipconfig` in CMD
- **macOS/Linux**: Run `ifconfig` or `ip addr` in terminal
- Look for your local network IP (usually starts with 192.168.x.x or 10.0.x.x)

### Environment Variables

The app uses secure storage for sensitive data. No additional environment files are needed.

## 📱 App Features

### Authentication

- **Sign Up**: Create new account with email/password
- **Sign In**: Login with existing credentials
- **JWT Token Management**: Automatic token handling and refresh
- **Secure Storage**: Credentials stored securely using Flutter Secure Storage

### Rock Classification

- **Camera Integration**: Take photos directly in the app
- **Gallery Selection**: Choose images from device gallery
- **Real-time Classification**: Send images to backend API
- **XAI Visualizations**: Display explainable AI results
- **Subscription Limits**: Respects user's subscription tier

### User Management

- **Profile Management**: View and update user information
- **Subscription Tiers**: Free, Premium, and Enterprise plans
- **Usage Tracking**: Monitor daily request limits
- **Feedback System**: Submit feedback on predictions

## 🔌 API Integration

### Endpoints Used

The app communicates with these backend endpoints:

- `POST /api/user/register` - User registration
- `POST /api/user/login` - User authentication
- `POST /api/user/logout` - User logout
- `GET /api/user/profile` - Get user profile
- `POST /api/predict` - Image classification
- `GET /api/predictions/{user_id}` - Get prediction history
- `POST /api/feedback/submit` - Submit feedback
- `GET /api/subscription/status` - Get subscription status
- `POST /api/subscription/upgrade` - Upgrade subscription

### Authentication Flow

1. **Registration/Login**: User provides credentials
2. **Token Storage**: JWT token stored securely
3. **Automatic Headers**: Token automatically added to all API requests
4. **Token Refresh**: Automatic handling of expired tokens
5. **Logout**: Token removed from secure storage

### Error Handling

The app includes comprehensive error handling:

- **Network Errors**: Connection timeouts, server errors
- **Authentication Errors**: Invalid credentials, expired tokens
- **Rate Limiting**: Daily request limits exceeded
- **Validation Errors**: Invalid input data
- **User Feedback**: Clear error messages for users

## 🧪 Testing

### Local Testing

1. **Start Backend Server**:

   ```bash
   cd ../Rock\ classification
   python api/app.py
   ```

2. **Update App Config**:

   ```dart
   // In lib/config/app_config.dart
   static const String baseUrl = 'http://10.0.2.2:8000/api';
   ```

3. **Run Flutter App**:
   ```bash
   flutter run
   ```

### Network Testing

The app includes a connection test feature:

```dart
// Test backend connectivity
final apiService = ApiService();
final isConnected = await apiService.testConnection();
print('Backend connected: $isConnected');
```

## 📊 Monitoring and Debugging

### Logging

Enable detailed logging in `lib/config/app_config.dart`:

```dart
static const bool enableApiLogging = true;
static const bool enableNetworkLogging = true;
```

### Debug Information

The app provides debug information for:

- API request/response logs
- Authentication status
- Network connectivity
- Subscription usage
- Error details

## 🔒 Security Features

### Data Protection

- **Secure Storage**: Sensitive data encrypted
- **JWT Tokens**: Stateless authentication
- **HTTPS**: Secure communication (when backend supports it)
- **Input Validation**: Client-side data validation

### Permission Handling

- **Camera Access**: Required for image capture
- **Storage Access**: Required for image selection
- **Network Access**: Required for API communication

## 🚨 Troubleshooting

### Common Issues

#### 1. Connection Refused

```
Error: Connection refused
```

**Solution**: Ensure backend server is running and accessible

#### 2. Authentication Failed

```
Error: Authentication failed. Please log in again.
```

**Solution**: Check if JWT token is valid, try logging in again

#### 3. Image Upload Fails

```
Error: Image size too large
```

**Solution**: Ensure image is under 10MB limit

#### 4. Rate Limit Exceeded

```
Error: Daily limit reached
```

**Solution**: Upgrade subscription or wait until tomorrow

### Debug Steps

1. **Check Backend Status**:

   ```bash
   curl http://localhost:8000/api/health
   ```

2. **Verify Network Configuration**:

   - Check IP address in `app_config.dart`
   - Ensure firewall allows connections
   - Verify backend port (8000)

3. **Check Flutter Logs**:

   ```bash
   flutter logs
   ```

4. **Test API Endpoints**:
   Use Postman or curl to test backend endpoints directly

## 📱 Platform-Specific Notes

### Android

- **Network Security**: Add network security config for HTTP connections
- **Permissions**: Camera and storage permissions required
- **Emulator**: Use `10.0.2.2` for localhost access

### iOS

- **Network Security**: Configure App Transport Security for HTTP
- **Permissions**: Camera and photo library permissions required
- **Simulator**: Use actual IP address for localhost access

## 🔄 Updates and Maintenance

### Regular Maintenance

1. **Update Dependencies**:

   ```bash
   flutter pub upgrade
   ```

2. **Regenerate Models**:

   ```bash
   flutter packages pub run build_runner build
   ```

3. **Check Backend Compatibility**:
   - Verify API endpoints haven't changed
   - Update response parsing if needed
   - Test authentication flow

### Version Compatibility

The app is designed to work with the backend API version specified in the main README.md. Ensure both frontend and backend are compatible.

## 📞 Support

### Getting Help

1. **Check Logs**: Enable logging and check for error details
2. **Verify Configuration**: Ensure backend URL and settings are correct
3. **Test Connectivity**: Use the connection test feature
4. **Check Backend**: Ensure backend server is running and healthy

### Reporting Issues

When reporting issues, include:

- Flutter version: `flutter --version`
- Device/emulator details
- Backend server status
- Error logs and stack traces
- Steps to reproduce the issue

## 🎯 Next Steps

After successful setup:

1. **Test Authentication**: Try signing up and signing in
2. **Test Classification**: Take a photo and classify a rock
3. **Test Feedback**: Submit feedback on predictions
4. **Test Subscriptions**: Check subscription management
5. **Monitor Usage**: Track API usage and limits

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Backend API Documentation](README.md)

---

**Note**: This app is designed to work with the rock classification backend. Ensure the backend is properly configured and running before testing the Flutter app.
