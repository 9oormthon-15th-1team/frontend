import 'package:flutter/material.dart';
import 'package:frontend/core/theme/tokens/app_typography.dart';
import '../../../core/models/pothole.dart';

class PotholeListItem extends StatelessWidget {
  final Pothole pothole;
  final VoidCallback onDetailTap;
  final VoidCallback onNavigateTap;

  const PotholeListItem({
    super.key,
    required this.pothole,
    required this.onDetailTap,
    required this.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetailTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 (위험 표시 + 거리)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측: 위험 아이콘 + "위험" 텍스트
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 20,
                      color: _getIconColor(pothole.severity),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getSeverityDisplayName(pothole.severity),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                  ],
                ),
                // 우측: 거리 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5D6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _calculateDistance(pothole),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ],
            ),

            // 주소 정보
            const SizedBox(height: 12),
            Text(
              pothole.address ??
                  '${pothole.latitude.toStringAsFixed(6)}, ${pothole.longitude.toStringAsFixed(6)}',
              style: AppTypography.bodyDefault,
            ),

            // 시간 정보
            const SizedBox(height: 6),
            Text(
              '${_formatDate(pothole.createdAt)} 신고',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9E9E9E),
              ),
            ),

            // AI 설명 박스
            if (pothole.description != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pothole.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF5A5A5A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIconColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
      case '위험':
        return const Color(0xFFE53E3E); // 빨간색 (높음)
      case 'medium':
      case 'moderate':
      case '주의':
        return const Color(0xFFF59E0B); // 노란색 (중간)
      case 'low':
      case 'minor':
      case '미학인':
        return const Color(0xFF9CA3AF); // 회색 (낮음)
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
      case '위험':
        return Colors.red;
      case 'medium':
      case 'moderate':
      case '주의':
        return Colors.orange;
      case 'low':
      case 'minor':
      case '미학인':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityDisplayName(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return '위험';
      case 'medium':
      case 'moderate':
        return '주의';
      case 'low':
      case 'minor':
        return '미학인';
      default:
        return severity;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '1일 전';
    } else {
      return '$difference일 전';
    }
  }

  String _calculateDistance(Pothole pothole) {
    // TODO: Calculate actual distance using current location
    // For now, return a mock distance
    return '${(pothole.id * 0.3 + 1.5).toStringAsFixed(1)}km';
  }
}
