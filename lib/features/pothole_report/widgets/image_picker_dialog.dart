import 'package:flutter/material.dart';

/// 이미지 선택 옵션을 보여주는 다이얼로그
class ImagePickerDialog extends StatelessWidget {
  const ImagePickerDialog({
    super.key,
    this.allowMultiple = true,
  });

  final bool allowMultiple;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 제목
          const Text(
            '사진 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 옵션들
          _buildOption(
            context,
            icon: Icons.camera_alt,
            title: '카메라로 촬영',
            subtitle: '새로운 사진을 촬영합니다',
            onTap: () => Navigator.of(context).pop('camera'),
          ),
          const SizedBox(height: 12),

          _buildOption(
            context,
            icon: Icons.photo_library,
            title: allowMultiple ? '갤러리에서 선택' : '갤러리에서 1장 선택',
            subtitle: allowMultiple
                ? '여러 장의 사진을 선택할 수 있습니다'
                : '갤러리에서 사진 1장을 선택합니다',
            onTap: () => Navigator.of(context).pop('gallery'),
          ),
          const SizedBox(height: 20),

          // 취소 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('취소'),
            ),
          ),

          // 하단 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 선택 다이얼로그를 표시하고 선택된 옵션을 반환
  static Future<String?> show(
    BuildContext context, {
    bool allowMultiple = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ImagePickerDialog(allowMultiple: allowMultiple),
    );
  }
}