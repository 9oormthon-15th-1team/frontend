import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pothole_marker.dart';

/// 포트홀 마커 위젯
class PotholeMarkerWidget extends StatelessWidget {
  final PotholeMarker marker;
  final double size;

  const PotholeMarkerWidget({
    super.key,
    required this.marker,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (marker.type) {
      case PotholeMarkerType.individual:
        return _buildTriangleWarningMarker();
      case PotholeMarkerType.cluster:
        return _buildCircleNumberMarker();
    }
  }

  /// 삼각형 경고 마커 (개별 포트홀용)
  Widget _buildTriangleWarningMarker() {
    final svgAsset = _getWarningSvgAsset(marker.riskLevel);

    return SvgPicture.asset(svgAsset, width: size, height: size);
  }

  /// 원형 숫자 마커 (클러스터용)
  Widget _buildCircleNumberMarker() {
    final color = _getRiskColor(marker.riskLevel);
    final count = marker.count;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: _getFontSize(count),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 위험도에 따른 색상 반환
  Color _getRiskColor(PotholeRiskLevel riskLevel) {
    switch (riskLevel) {
      case PotholeRiskLevel.low:
        return const Color(0xFFFFC107); // 노란색
      case PotholeRiskLevel.medium:
        return const Color(0xFFFF9800); // 주황색
      case PotholeRiskLevel.high:
        return const Color(0xFFF44336); // 빨간색
    }
  }

  /// 위험도에 따른 경고 SVG 아이콘 반환
  String _getWarningSvgAsset(PotholeRiskLevel riskLevel) {
    switch (riskLevel) {
      case PotholeRiskLevel.low:
        return 'assets/images/warning_yellow.svg';
      case PotholeRiskLevel.medium:
        return 'assets/images/warning_orange.svg';
      case PotholeRiskLevel.high:
        return 'assets/images/warning_red.svg';
    }
  }

  /// 숫자에 따른 폰트 크기 계산
  double _getFontSize(int count) {
    if (count < 10) return size * 0.5;
    if (count < 100) return size * 0.4;
    return size * 0.35;
  }
}

/// 삼각형 경고 마커 페인터
class TriangleWarningPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  TriangleWarningPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // 삼각형 경로 생성 (위쪽 정점이 있는 삼각형)
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.5, 0); // 상단 중앙
    path.lineTo(width, height); // 우하단
    path.lineTo(0, height); // 좌하단
    path.close();

    // 그림자 효과
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.save();
    canvas.translate(1, 1);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 삼각형 채우기
    canvas.drawPath(path, paint);

    // 삼각형 테두리
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

/// 마커 크기 상수
class MarkerSizes {
  static const double small = 24.0;
  static const double medium = 32.0;
  static const double large = 40.0;
}
