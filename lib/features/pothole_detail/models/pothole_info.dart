/// 포트홀 상세 정보 모델
class PotholeInfo {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final List<String> images;
  final String status;
  final String severity;
  final DateTime? firstReportedAt;
  final DateTime? latestReportedAt;
  final int reportCount;
  final String? complaintId;

  const PotholeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    required this.images,
    required this.status,
    required this.severity,
    this.firstReportedAt,
    this.latestReportedAt,
    this.reportCount = 1,
    this.complaintId,
  });

  /// JSON에서 PotholeInfo 객체 생성
  factory PotholeInfo.fromJson(Map<String, dynamic> json) {
    return PotholeInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '포트홀 신고',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      status: json['status']?.toString() ?? 'pending',
      severity: json['severity']?.toString() ?? 'medium',
      firstReportedAt: json['firstReportedAt'] != null
          ? DateTime.tryParse(json['firstReportedAt'].toString())
          : null,
      latestReportedAt: json['latestReportedAt'] != null
          ? DateTime.tryParse(json['latestReportedAt'].toString())
          : null,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 1,
      complaintId: json['complaintId']?.toString(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'status': status,
      'severity': severity,
      'firstReportedAt': firstReportDate.toIso8601String(),
      'latestReportedAt': latestReportDate.toIso8601String(),
      'reportCount': reportCount,
      'complaintId': complaintId,
    };
  }

  /// 상태 한글 변환
  String get statusKorean {
    switch (status.toLowerCase()) {
      case 'pending':
        return '접수됨';
      case 'in_progress':
        return '처리중';
      case 'completed':
        return '완료됨';
      case 'rejected':
        return '반려됨';
      default:
        return '알 수 없음';
    }
  }

  /// 심각도 한글 변환
  String get severityKorean {
    switch (severity.toLowerCase()) {
      case 'low':
        return '낮음';
      case 'medium':
        return '보통';
      case 'high':
        return '높음';
      case 'critical':
        return '심각';
      default:
        return '보통';
    }
  }

  /// 상태별 색상
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // 주황색
      case 'in_progress':
        return '#2196F3'; // 파란색
      case 'completed':
        return '#4CAF50'; // 초록색
      case 'rejected':
        return '#F44336'; // 빨간색
      default:
        return '#9E9E9E'; // 회색
    }
  }

  /// 표시할 이미지 개수 (최대 6개)
  List<String> get displayImages {
    return images.length > 6 ? images.take(6).toList() : images;
  }

  /// 최초 신고 일자 (없다면 createdAt 사용)
  DateTime get firstReportDate => firstReportedAt ?? createdAt;

  /// 최신 신고 일자 (없다면 createdAt 사용)
  DateTime get latestReportDate => latestReportedAt ?? createdAt;

  /// 추가 신고 횟수 (최소 0)
  int get additionalReportCount => reportCount > 1 ? reportCount - 1 : 0;

  /// 추가 이미지 개수
  int get additionalImageCount {
    return images.length > 6 ? images.length - 6 : 0;
  }

  /// 복사본 생성
  PotholeInfo copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    List<String>? images,
    String? status,
    String? severity,
    DateTime? firstReportedAt,
    DateTime? latestReportedAt,
    int? reportCount,
    String? complaintId,
  }) {
    return PotholeInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      firstReportedAt: firstReportedAt ?? this.firstReportedAt,
      latestReportedAt: latestReportedAt ?? this.latestReportedAt,
      reportCount: reportCount ?? this.reportCount,
      complaintId: complaintId ?? this.complaintId,
    );
  }

  @override
  String toString() {
    return 'PotholeInfo(id: $id, title: $title, address: $address, images: ${images.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PotholeInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
