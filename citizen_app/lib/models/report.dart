import 'package:intl/intl.dart';
import 'user.dart';

class ReportUpdate {
  final int id;
  final String status;
  final String? note;
  final User? updatedBy;
  final DateTime createdAt;

  ReportUpdate({
    required this.id,
    required this.status,
    this.note,
    this.updatedBy,
    required this.createdAt,
  });

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      note: json['note'] ?? json['notes'],
      updatedBy: json['updated_by'] != null
          ? User.fromJson(json['updated_by'])
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

  String? get notes => note;
}

class GarbageReport {
  final int id;
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
  final List<ReportUpdate> updates;

  GarbageReport({
    required this.id,
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

  factory GarbageReport.fromJson(Map<String, dynamic> json) {
    return GarbageReport(
      id: json['id'] ?? 0,
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
                .map((u) => ReportUpdate.fromJson(u))
                .toList()
          : [],
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

  String get wasteTypeDisplay {
    switch (wasteType) {
      case 'organic':
        return 'Organic';
      case 'recyclable':
        return 'Recyclable';
      case 'hazardous':
        return 'Hazardous';
      case 'electronic':
        return 'E-Waste';
      case 'mixed':
        return 'Mixed';
      default:
        return wasteType;
    }
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy h:mm a').format(createdAt);
  }

  String? get assignedCollector {
    return assignedTo != null
        ? '${assignedTo!.firstName} ${assignedTo!.lastName}'
        : null;
  }
}
