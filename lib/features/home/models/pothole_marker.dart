import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 포트홀 마커 타입
enum PotholeMarkerType {
  /// 개별 포트홀 (삼각형 경고 마커)
  individual,
  /// 클러스터 (원형 숫자 마커)
  cluster,
}

/// 포트홀 위험도 수준
enum PotholeRiskLevel {
  low,    // 낮음 (노란색)
  medium, // 보통 (주황색)
  high,   // 높음 (빨간색)
}

/// 포트홀 데이터 모델
class PotholeData {
  final String id;
  final double latitude;
  final double longitude;
  final PotholeRiskLevel riskLevel;
  final String description;
  final DateTime reportedAt;
  final String? imageUrl;
  final String status;

  const PotholeData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
    required this.description,
    required this.reportedAt,
    this.imageUrl,
    this.status = 'medium',
  });

  /// 위치 정보를 NLatLng로 변환
  NLatLng get position => NLatLng(latitude, longitude);

  factory PotholeData.fromJson(Map<String, dynamic> json) {
    return PotholeData(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      riskLevel: PotholeRiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => PotholeRiskLevel.medium,
      ),
      description: json['description'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      status: (json['status'] ?? json['size'] ?? json['riskLevel'] ?? 'medium')
          .toString()
          .toLowerCase(),
    );
  }
}

/// 포트홀 클러스터 데이터
class PotholeCluster {
  final String id;
  final double latitude;
  final double longitude;
  final int count;
  final List<PotholeData> potholes;

  const PotholeCluster({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.potholes,
  });

  /// 위치 정보를 NLatLng로 변환
  NLatLng get position => NLatLng(latitude, longitude);

  /// 클러스터 내 최고 위험도 계산
  PotholeRiskLevel get maxRiskLevel {
    if (potholes.isEmpty) return PotholeRiskLevel.low;

    return potholes
        .map((p) => p.riskLevel)
        .reduce((a, b) => a.index > b.index ? a : b);
  }
}

/// 포트홀 마커 데이터
class PotholeMarker {
  final String id;
  final PotholeMarkerType type;
  final NLatLng position;
  final PotholeData? potholeData;
  final PotholeCluster? clusterData;

  const PotholeMarker({
    required this.id,
    required this.type,
    required this.position,
    this.potholeData,
    this.clusterData,
  });

  /// 개별 포트홀 마커 생성
  factory PotholeMarker.individual(PotholeData pothole) {
    return PotholeMarker(
      id: 'pothole_${pothole.id}',
      type: PotholeMarkerType.individual,
      position: pothole.position,
      potholeData: pothole,
    );
  }

  /// 클러스터 마커 생성
  factory PotholeMarker.cluster(PotholeCluster cluster) {
    return PotholeMarker(
      id: 'cluster_${cluster.id}',
      type: PotholeMarkerType.cluster,
      position: cluster.position,
      clusterData: cluster,
    );
  }

  /// 위험도 레벨 반환
  PotholeRiskLevel get riskLevel {
    switch (type) {
      case PotholeMarkerType.individual:
        return potholeData?.riskLevel ?? PotholeRiskLevel.medium;
      case PotholeMarkerType.cluster:
        return clusterData?.maxRiskLevel ?? PotholeRiskLevel.medium;
    }
  }

  /// 상태(마커 이미지 매핑용)
  String get status => potholeData?.status ?? 'medium';

  /// 표시할 숫자 (클러스터의 경우)
  int get count => clusterData?.count ?? 1;
}
