class Pothole {
  final int id;
  final double latitude;
  final double longitude;
  final String severity;
  final String status;
  final DateTime createdAt;
  final String? description;

  Pothole({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory Pothole.fromJson(Map<String, dynamic> json) {
    return Pothole(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'unknown',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'description': description,
    };
  }
}