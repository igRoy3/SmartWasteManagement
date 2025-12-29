import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../utils/api_constants.dart';

class ReportService {
  final String token;

  ReportService(this.token);

  Future<List<GarbageReport>> getAllReports() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? data;
        return results.map((json) => GarbageReport.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get reports error: $e');
      return [];
    }
  }

  Future<List<GarbageReport>> getMyReports() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myReports}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? data;
        return results.map((json) => GarbageReport.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get my reports error: $e');
      return [];
    }
  }

  Future<bool> createReport(GarbageReport report, {File? imageFile}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['title'] = report.title;
      request.fields['description'] = report.description;
      request.fields['garbage_type'] = report.garbageType;
      request.fields['latitude'] = report.latitude.toString();
      request.fields['longitude'] = report.longitude.toString();
      request.fields['address'] = report.address;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Create report error: $e');
      return false;
    }
  }

  Future<GarbageReport?> getReportById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GarbageReport.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get report by ID error: $e');
      return null;
    }
  }
}
