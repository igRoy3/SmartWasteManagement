import 'package:intl/intl.dart';
import 'user.dart';

/// Task Update model for status history
class TaskUpdate {
  final int id;
  final String status;
  final String? note;
  final User? updatedBy;
  final DateTime createdAt;

  TaskUpdate({
    required this.id,
    required this.status,
    this.note,
    this.updatedBy,
    required this.createdAt,
  });

  factory TaskUpdate.fromJson(Map<String, dynamic> json) {
    return TaskUpdate(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      note: json['note'] ?? json['notes'],
      updatedBy: json['updated_by'] != null
          ? (json['updated_by'] is Map
                ? User.fromJson(json['updated_by'])
                : null)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy h:mm a').format(createdAt);
  }
}

/// Task model representing a garbage collection task
class Task {
  final int id;
  final String? title;
  final String? description;
  final String wasteType;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? image;
  final String status;
  final User? reportedBy;
  final User? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<TaskUpdate> updates;

  Task({
    required this.id,
    this.title,
    this.description,
    required this.wasteType,
    this.latitude,
    this.longitude,
    this.address,
    this.image,
    required this.status,
    this.reportedBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.updates = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'],
      description: json['description'],
      wasteType: json['waste_type'] ?? 'mixed',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      address: json['address'],
      image: json['image'],
      status: json['status'] ?? 'pending',
      reportedBy: json['reported_by'] != null
          ? (json['reported_by'] is Map
                ? User.fromJson(json['reported_by'])
                : null)
          : null,
      assignedTo: json['assigned_to'] != null
          ? (json['assigned_to'] is Map
                ? User.fromJson(json['assigned_to'])
                : null)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      updates: json['updates'] != null
          ? (json['updates'] as List)
                .map((u) => TaskUpdate.fromJson(u))
                .toList()
          : [],
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(createdAt);
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get wasteTypeDisplay {
    switch (wasteType) {
      case 'organic':
        return 'Organic Waste';
      case 'recyclable':
        return 'Recyclable Waste';
      case 'hazardous':
        return 'Hazardous Waste';
      case 'electronic':
        return 'Electronic Waste';
      case 'mixed':
        return 'Mixed Waste';
      default:
        return wasteType;
    }
  }

  String get locationSummary {
    if (address != null && address!.isNotEmpty) {
      // Return first 50 chars of address
      return address!.length > 50
          ? '${address!.substring(0, 50)}...'
          : address!;
    }
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'Location not available';
  }

  bool get hasLocation => latitude != null && longitude != null;

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' || status == 'assigned';
  bool get isInProgress => status == 'in_progress';
}
