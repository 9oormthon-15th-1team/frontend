import 'pothole_status.dart';

class Pothole {
  final int id;
  final double latitude;
  final double longitude;
  final PotholeStatus status;
  final DateTime createdAt;
  final String description;
  final String address;
  final String? aiSummary;
  final String? complaintId;
  final List<String> images;

  Pothole({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.address = '',
    this.aiSummary,
    this.complaintId,
    this.images = const [],
  });

  factory Pothole.fromJson(Map<String, dynamic> json) {
    return Pothole(
      id: _parseInt(json['id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: PotholeStatus.fromServerValue(
        json['markerStatus'] ?? json['status'],
      ),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['reportedAt'],
      ),
      description: _parseNullableString(
        json['description'] ?? json['details'] ?? json['content'],
      ) ?? '',
      address: _parseNullableString(
        json['address'] ?? json['location'] ?? json['roadName'],
      ) ?? '',
      aiSummary: _parseNullableString(
        json['aiSummary'] ?? json['ai_summary'] ?? json['summary'],
      ),
      complaintId: _parseNullableString(json['complaintId']),
      images: _parseImages(json),
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
      'description': description,
      'ai_summary': aiSummary,
      'complaintId': complaintId,
      'images': images,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    final candidates = [
      json['images'],
      json['imageUrls'],
      json['image_urls'],
      json['imagePaths'],
      json['image_paths'],
      json['photos'],
    ];

    for (final candidate in candidates) {
      final list = _normalizeToStringList(candidate);
      if (list.isNotEmpty) {
        return list;
      }
    }

    final singleImage = _parseNullableString(json['imageUrl']);
    if (singleImage != null) {
      return [singleImage];
    }

    return const [];
  }

  static List<String> _normalizeToStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .where((element) => element != null)
          .map((element) => element.toString())
          .where((element) => element.trim().isNotEmpty)
          .toList();
    }

    if (value is String) {
      if (value.trim().isEmpty) return const [];
      if (value.contains(',')) {
        return value
            .split(',')
            .map((element) => element.trim())
            .where((element) => element.isNotEmpty)
            .toList();
      }
      return [value.trim()];
    }

    return const [];
  }
}
