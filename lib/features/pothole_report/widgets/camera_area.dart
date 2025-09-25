import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 점선 테두리를 그리는 커스텀 페인터
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 2.0,
    this.dashLength = 8.0,
    this.gapLength = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
    );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(
          distance,
          distance + dashLength,
        );
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 포트홀 사진 촬영/선택을 위한 중앙 카메라 영역
class CameraArea extends StatelessWidget {
  const CameraArea({
    super.key,
    required this.hasImages,
    this.latestImage,
    required this.imageCountText,
    required this.onTap,
  });

  final bool hasImages;
  final XFile? latestImage;
  final String imageCountText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final areaHeight = screenWidth * 0.6; // 화면 너비의 60%

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: areaHeight,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: Colors.grey[400]!,
            strokeWidth: 2.0,
          ),
          child: hasImages ? _buildImageView() : _buildEmptyView(),
        ),
      ),
    );
  }

  /// 빈 상태 UI
  Widget _buildEmptyView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '사진을 추가해주세요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '탭하여 카메라나 갤러리에서 선택',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지가 있는 상태 UI
  Widget _buildImageView() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // 대표 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: latestImage != null
                  ? Image.file(
                      File(latestImage!.path),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),

          // 이미지 개수 표시
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                imageCountText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 터치 영역 표시 (선택사항)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withValues(alpha: 0.05),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}