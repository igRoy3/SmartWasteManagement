import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../utils/api_constants.dart';

class TaskService {
  final String token;

  TaskService(this.token);

  Future<List<CollectionTask>> getAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? data;
        return results.map((json) => CollectionTask.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get tasks error: $e');
      return [];
    }
  }

  Future<List<CollectionTask>> getMyTasks() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myTasks}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? data;
        return results.map((json) => CollectionTask.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get my tasks error: $e');
      return [];
    }
  }

  Future<bool> createTask(int reportId, int collectorId, String priority, String? notes) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'report': reportId,
          'collector': collectorId,
          'priority': priority,
          'notes': notes,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create task error: $e');
      return false;
    }
  }

  Future<bool> updateTaskStatus(int taskId, String status, String? completionNotes) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}$taskId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'completion_notes': completionNotes,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update task status error: $e');
      return false;
    }
  }
}
