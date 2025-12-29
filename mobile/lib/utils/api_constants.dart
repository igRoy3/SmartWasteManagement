class ApiConstants {
  // Update this URL to your backend server URL
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For iOS simulator: use localhost
  // For real device: use your computer's IP address or production URL
  static const String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  // Auth endpoints
  static const String register = '/api/auth/register/';
  static const String login = '/api/auth/login/';
  static const String tokenRefresh = '/api/auth/token/refresh/';
  static const String profile = '/api/auth/profile/';
  
  // Reports endpoints
  static const String reports = '/api/reports/';
  static const String myReports = '/api/reports/my-reports/';
  
  // Tasks endpoints
  static const String tasks = '/api/tasks/';
  static const String myTasks = '/api/tasks/my-tasks/';
}
