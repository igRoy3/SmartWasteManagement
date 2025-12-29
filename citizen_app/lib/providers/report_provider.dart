import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

class ReportProvider with ChangeNotifier {
  List<GarbageReport> _reports = [];
  GarbageReport? _selectedReport;
  bool _isLoading = false;
  String? _error;

  List<GarbageReport> get reports => _reports;
  GarbageReport? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports(AuthProvider authProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authProvider.authenticatedRequest(
        'GET',
        ApiConstants.citizenReports,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data is List
            ? data
            : (data['results'] ?? []);
        _reports = results.map((r) => GarbageReport.fromJson(r)).toList();
      } else {
        _error = 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReportDetail(
    AuthProvider authProvider,
    int reportId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authProvider.authenticatedRequest(
        'GET',
        ApiConstants.citizenReportDetail(reportId),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _selectedReport = GarbageReport.fromJson(data);
      } else {
        _error = 'Failed to load report';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReport({
    required AuthProvider authProvider,
    required String title,
    required String description,
    required String wasteType,
    required double latitude,
    required double longitude,
    required String address,
    File? image,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.citizenReports),
      );

      request.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['waste_type'] = wasteType;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Report creation response status: ${response.statusCode}');
      print('Report creation response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newReport = GarbageReport.fromJson(data);
        _reports.insert(0, newReport);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Report creation error: $e');
      _error = 'Failed to create report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSelectedReport() {
    _selectedReport = null;
    notifyListeners();
  }

  // Get reports count by status
  int getCountByStatus(String status) {
    return _reports.where((r) => r.status == status).length;
  }
}
