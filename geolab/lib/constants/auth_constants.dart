class AuthConstants {
  // Existing constants
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  
  // Token prefixes
  static const String bearerPrefix = 'Bearer ';
  
  // Existing API endpoints
  static const String loginEndpoint = '/user/login';
  static const String registerEndpoint = '/user/register';
  static const String logoutEndpoint = '/user/logout';
  static const String refreshEndpoint = '/user/refresh';
  
  // New OTP API endpoints
  static const String sendOtpEndpoint = '/user/send-otp';
  static const String resendOtpEndpoint = '/user/resend-otp';
  static const String verifyOtpEndpoint = '/user/verify-otp';
  static const String verifyOtpRegisterEndpoint = '/user/verify-otp-register';
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpResendDelaySeconds = 60;
  static const int otpExpiryMinutes = 10;
  
  // Error messages
  static const String otpRequiredError = 'Verification code is required';
  static const String otpInvalidError = 'Please enter a valid 6-digit code';
  static const String otpExpiredError = 'Verification code has expired';
  static const String otpIncorrectError = 'Invalid verification code';
}