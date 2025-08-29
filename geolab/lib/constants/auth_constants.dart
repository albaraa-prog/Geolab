class AuthConstants {
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Token prefixes
  static const String bearerPrefix = 'Bearer ';

  // API endpoints
  static const String loginEndpoint = '/user/login';
  static const String registerEndpoint = '/user/register';
  static const String logoutEndpoint = '/user/logout';
  static const String refreshEndpoint = '/user/refresh';
}
