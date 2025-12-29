class GarbageReport {
  final int? id;
  final String title;
  final String description;
  final String garbageType;
  final String status;
  final double latitude;
  final double longitude;
  final String address;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GarbageReport({
    this.id,
    required this.title,
    required this.description,
    required this.garbageType,
    this.status = 'pending',
    required this.latitude,
    required this.longitude,
    required this.address,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory GarbageReport.fromJson(Map<String, dynamic> json) {
    return GarbageReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      garbageType: json['garbage_type'],
      status: json['status'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'],
      image: json['image'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'garbage_type': garbageType,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
