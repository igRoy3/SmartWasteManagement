import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/task_service.dart';
import '../../models/report.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<GarbageReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final reportService = ReportService(authService.token!);
    
    final reports = await reportService.getAllReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
        onRefresh: _loadReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? const Center(child: Text('No reports found'))
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(report.status),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(report.title),
                          subtitle: Text(
                            '${report.garbageType} - ${report.status}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Description: ${report.description}'),
                                  const SizedBox(height: 8),
                                  Text('Address: ${report.address}'),
                                  const SizedBox(height: 8),
                                  Text('Location: ${report.latitude}, ${report.longitude}'),
                                  const SizedBox(height: 16),
                                  if (report.status == 'pending')
                                    ElevatedButton(
                                      onPressed: () {
                                        _showAssignDialog(context, report);
                                      },
                                      child: const Text('Assign to Collector'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAssignDialog(BuildContext context, GarbageReport report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Task'),
          content: const Text('Task assignment feature requires collector list. '
              'In a full implementation, you would select a collector from a list here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // In a full implementation, you would:
                // 1. Show a list of available collectors
                // 2. Let admin select one
                // 3. Call taskService.createTask()
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task assignment not fully implemented in this demo'),
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}
