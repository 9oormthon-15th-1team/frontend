import '../../../core/models/pothole.dart';
import '../models/pothole_info.dart';

/// Pothole 모델을 PotholeInfo 모델로 변환하는 유틸리티 클래스
class PotholeMapper {
  /// Pothole을 PotholeInfo로 변환
  static PotholeInfo fromPothole(Pothole pothole) {
    return PotholeInfo(
      id: pothole.id.toString(),
      title: '포트홀 신고 #${pothole.id}',
      description: pothole.description.isNotEmpty
          ? pothole.description
          : pothole.aiSummary ?? '포트홀이 발견되었습니다.',
      latitude: pothole.latitude,
      longitude: pothole.longitude,
      address: pothole.address,
      createdAt: pothole.createdAt,
      images: pothole.images,
      status: pothole.status,
      firstReportedAt: pothole.createdAt,
      latestReportedAt: pothole.createdAt,
      reportCount: 1,
      complaintId: pothole.complaintId,
    );
  }

  /// 여러 Pothole을 PotholeInfo 리스트로 변환
  static List<PotholeInfo> fromPotholeList(List<Pothole> potholes) {
    return potholes.map((pothole) => fromPothole(pothole)).toList();
  }

}
