import 'package:meta/meta.dart';

/// 포트홀 신고 데이터를 전송하기 위한 모델
@immutable
class PotholeReport {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String imageBase64;
  final String status;

  const PotholeReport({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.imageBase64,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'image': imageBase64,
      'status': status,
    };
  }
}
