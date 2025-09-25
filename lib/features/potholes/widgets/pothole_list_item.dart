import 'package:flutter/material.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getSeverityColor(pothole.severity),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSeverityDisplayName(pothole.severity),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pothole.latitude.toStringAsFixed(6)}, ${pothole.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(pothole.createdAt)} 신고 • 상태 ${pothole.status}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      if (pothole.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          pothole.description!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _calculateDistance(pothole),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetailTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF5722)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '상세보기',
                      style: TextStyle(
                        color: Color(0xFFFF5722),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNavigateTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '길안내',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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