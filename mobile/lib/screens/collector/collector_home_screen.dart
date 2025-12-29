import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  List<CollectionTask> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final taskService = TaskService(authService.token!);
    
    final tasks = await taskService.getMyTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _updateTaskStatus(CollectionTask task, String newStatus) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final taskService = TaskService(authService.token!);
    
    final success = await taskService.updateTaskStatus(
      task.id,
      newStatus,
      null,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task status updated')),
      );
      _loadTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
                ? const Center(child: Text('No tasks assigned yet'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final report = task.report;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPriorityColor(task.priority),
                            child: Icon(
                              _getPriorityIcon(task.priority),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(report['title'] ?? 'Unknown'),
                          subtitle: Text(
                            '${task.priority} priority - ${task.status}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Description: ${report['description']}'),
                                  const SizedBox(height: 8),
                                  Text('Address: ${report['address']}'),
                                  const SizedBox(height: 8),
                                  Text('Type: ${report['garbage_type']}'),
                                  const SizedBox(height: 8),
                                  Text('Location: ${report['latitude']}, ${report['longitude']}'),
                                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('Notes: ${task.notes}'),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (task.status == 'assigned')
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateTaskStatus(task, 'in_progress');
                                          },
                                          child: const Text('Start Task'),
                                        ),
                                      if (task.status == 'in_progress')
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateTaskStatus(task, 'completed');
                                          },
                                          child: const Text('Complete Task'),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Open map with location
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Map integration requires Google Maps API key',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.map),
                                        label: const Text('Navigate'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.help;
    }
  }
}
