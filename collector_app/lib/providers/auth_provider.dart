import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';

/// Authentication Provider for Collector App
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  final _storage = const FlutterSecureStorage();

  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null && _user != null;
  String? get error => _error;

  /// Initialize auth state from secure storage
  Future<bool> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accessToken = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');
      final userJson = await _storage.read(key: 'user');

      if (_accessToken != null && userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));

        // Verify user is a collector
        if (_user!.role != 'collector') {
          await logout();
          _error = 'This app is for collectors only';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Validate token by fetching profile
        final isValid = await _validateToken();
        if (!isValid) {
          await logout();
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Auth initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Validate token by fetching user profile
  Future<bool> _validateToken() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));
        return true;
      } else if (response.statusCode == 401) {
        // Try to refresh token
        return await _refreshAccessToken();
      }
    } catch (e) {
      print('Token validation error: $e');
    }
    return false;
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        await _storage.write(key: 'access_token', value: _accessToken);
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    return false;
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if user is a collector
        if (data['user']['role'] != 'collector') {
          _error = 'This app is for collectors only';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];
        _user = User.fromJson(data['user']);

        // Store credentials securely
        await _storage.write(key: 'access_token', value: _accessToken);
        await _storage.write(key: 'refresh_token', value: _refreshToken);
        await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? data['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'refresh': _refreshToken}),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }

    // Clear stored credentials
    await _storage.deleteAll();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _error = null;

    _isLoading = false;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;

      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.changePassword),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error =
            data['detail'] ??
            data['old_password']?.first ??
            'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Make authenticated request with auto token refresh
  Future<http.Response?> authenticatedRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          return null;
      }

      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          headers['Authorization'] = 'Bearer $_accessToken';
          switch (method.toUpperCase()) {
            case 'GET':
              return await http.get(Uri.parse(url), headers: headers);
            case 'POST':
              return await http.post(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              );
            case 'PUT':
              return await http.put(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              );
            case 'DELETE':
              return await http.delete(Uri.parse(url), headers: headers);
          }
        }
      }

      return response;
    } catch (e) {
      print('Authenticated request error: $e');
      return null;
    }
  }
}
