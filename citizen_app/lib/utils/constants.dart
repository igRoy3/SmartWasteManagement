class ApiConstants {
  // Change this to your computer's IP if testing on a physical device
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // For Android emulator use: 'http://10.0.2.2:8000/api'
  // For iOS simulator use: 'http://127.0.0.1:8000/api'
  // For physical device use your computer's local IP: 'http://192.168.x.x:8000/api'

  // Auth endpoints
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String changePassword = '$baseUrl/auth/change-password/';
  static const String tokenRefresh = '$baseUrl/auth/token/refresh/';

  // Citizen report endpoints
  static const String citizenReports = '$baseUrl/reports/citizen/reports/';

  static String citizenReportDetail(int id) =>
      '$baseUrl/reports/citizen/reports/$id/';
}
