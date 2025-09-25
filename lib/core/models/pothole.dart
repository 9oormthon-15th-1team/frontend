import 'pothole_status.dart';

class Pothole {
  final int id;
  final double latitude;
  final double longitude;
  final PotholeStatus status;
  final DateTime createdAt;
  final String? description;
  final String? address;
  final String? aiSummary;

  Pothole({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.description,
    this.address,
    this.aiSummary,
  });

  factory Pothole.fromJson(Map<String, dynamic> json) {
    return Pothole(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: PotholeStatus.fromServerValue(json['markerStatus']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      address: json['address'],
      aiSummary: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'markerStatus': status.toServerValue(),
      'created_at': createdAt.toIso8601String(),
      'address': address,
      'ai_summary': description,
    };
  }
}