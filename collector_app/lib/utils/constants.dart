/// API and App Constants for Collector App
class ApiConstants {
  // Base URL - use 10.0.2.2 for Android emulator to reach host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String changePassword = '$baseUrl/auth/change-password/';

  // Collector endpoints
  static const String collectorTasks = '$baseUrl/reports/collector/tasks/';
  static String collectorTaskDetail(int id) =>
      '$baseUrl/reports/collector/tasks/$id/';
  static String updateTaskStatus(int id) =>
      '$baseUrl/reports/collector/tasks/$id/update-status/';
}

class AppConstants {
  static const String appName = 'Smart Waste - Collector';
  static const String appVersion = '1.0.0';
}
