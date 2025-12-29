class ApiConstants {
  // Update this URL to your backend server URL
  static const String baseUrl = 'http://localhost:8000';
  
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
