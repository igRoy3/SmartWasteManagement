import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../models/report.dart';
import 'create_report_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
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
    
    final reports = await reportService.getMyReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
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
                ? const Center(
                    child: Text('No reports yet. Tap + to create one!'),
                  )
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(report.status),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(report.title),
                          subtitle: Text(
                            '${report.garbageType} - ${report.status}',
                          ),
                          trailing: Text(
                            _formatDate(report.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            // Navigate to report details
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateReportScreen(),
            ),
          );
          _loadReports();
        },
        icon: const Icon(Icons.add),
        label: const Text('Report Garbage'),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
