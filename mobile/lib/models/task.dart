class CollectionTask {
  final int id;
  final Map<String, dynamic> report;
  final Map<String, dynamic>? collector;
  final String status;
  final String priority;
  final String? notes;
  final String? completionNotes;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  CollectionTask({
    required this.id,
    required this.report,
    this.collector,
    required this.status,
    required this.priority,
    this.notes,
    this.completionNotes,
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
  });

  factory CollectionTask.fromJson(Map<String, dynamic> json) {
    return CollectionTask(
      id: json['id'],
      report: json['report'],
      collector: json['collector'],
      status: json['status'],
      priority: json['priority'],
      notes: json['notes'],
      completionNotes: json['completion_notes'],
      assignedAt: DateTime.parse(json['assigned_at']),
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }
}
