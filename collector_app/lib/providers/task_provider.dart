import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

/// Task Provider for managing collector tasks
class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  Task? _selectedTask;
  bool _isLoading = false;
  String? _error;

  // Stats
  int _totalAssigned = 0;
  int _completedToday = 0;
  int _inProgress = 0;

  List<Task> get tasks => _tasks;
  Task? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalAssigned => _totalAssigned;
  int get completedToday => _completedToday;
  int get inProgress => _inProgress;

  /// Fetch all assigned tasks
  Future<void> fetchTasks(AuthProvider authProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authProvider.authenticatedRequest(
        'GET',
        ApiConstants.collectorTasks,
      );

      if (response == null) {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Fetch tasks response status: ${response.statusCode}');
      print('Fetch tasks response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both list and paginated response
        List<dynamic> taskList;
        if (data is List) {
          taskList = data;
        } else if (data is Map && data.containsKey('results')) {
          taskList = data['results'];
        } else {
          taskList = [];
        }

        _tasks = taskList.map((t) => Task.fromJson(t)).toList();
        _calculateStats();
      } else {
        _error = 'Failed to fetch tasks';
      }
    } catch (e) {
      print('Fetch tasks error: $e');
      _error = 'Error loading tasks: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch task detail by ID
  Future<void> fetchTaskDetail(AuthProvider authProvider, int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await authProvider.authenticatedRequest(
        'GET',
        ApiConstants.collectorTaskDetail(taskId),
      );

      if (response == null) {
        _error = 'Network error';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _selectedTask = Task.fromJson(data);
      } else {
        _error = 'Failed to load task details';
      }
    } catch (e) {
      print('Fetch task detail error: $e');
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update task status
  Future<bool> updateTaskStatus(
    AuthProvider authProvider,
    int taskId,
    String newStatus, {
    String? note,
    File? completionImage,
  }) async {
    _isLoading = true;
    _error = null;
    // Don't notify here - let the UI handle loading state

    try {
      http.Response response;

      if (completionImage != null) {
        // Use multipart request for image upload
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConstants.updateTaskStatus(taskId)),
        );

        request.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';
        request.fields['status'] = newStatus;
        if (note != null && note.isNotEmpty) {
          request.fields['note'] = note;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'completion_image',
            completionImage.path,
          ),
        );

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Regular JSON request
        final res = await authProvider.authenticatedRequest(
          'POST',
          ApiConstants.updateTaskStatus(taskId),
          body: {
            'status': newStatus,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );

        if (res == null) {
          _error = 'Network error';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        response = res;
      }

      print('Update status response: ${response.statusCode}');
      print('Update status body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTask = Task.fromJson(data);

        // Update task in list (keep completed tasks for viewing)
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }

        _selectedTask = updatedTask;
        _calculateStats();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? data['detail'] ?? 'Failed to update status';
      }
    } catch (e) {
      print('Update status error: $e');
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Start working on a task (set to in_progress)
  Future<bool> startTask(AuthProvider authProvider, int taskId) async {
    return await updateTaskStatus(authProvider, taskId, 'in_progress');
  }

  /// Complete a task
  Future<bool> completeTask(
    AuthProvider authProvider,
    int taskId, {
    String? note,
    File? completionImage,
  }) async {
    return await updateTaskStatus(
      authProvider,
      taskId,
      'completed',
      note: note,
      completionImage: completionImage,
    );
  }

  /// Calculate stats from tasks
  void _calculateStats() {
    _totalAssigned = _tasks.length;
    _inProgress = _tasks.where((t) => t.status == 'in_progress').length;

    // Count completed today (from updates if available)
    final today = DateTime.now();
    _completedToday = _tasks.where((t) {
      if (t.completedAt == null) return false;
      return t.completedAt!.year == today.year &&
          t.completedAt!.month == today.month &&
          t.completedAt!.day == today.day;
    }).length;
  }

  /// Clear selected task
  void clearSelectedTask() {
    _selectedTask = null;
    notifyListeners();
  }

  /// Get tasks by status
  List<Task> getTasksByStatus(String status) {
    return _tasks.where((t) => t.status == status).toList();
  }

  /// Get pending tasks (assigned but not started)
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == 'assigned').toList();

  /// Get in-progress tasks
  List<Task> get inProgressTasks =>
      _tasks.where((t) => t.status == 'in_progress').toList();
}
