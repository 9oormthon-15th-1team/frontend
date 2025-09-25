import 'package:flutter/material.dart';
import 'package:frontend/core/theme/design_system.dart';

/// 액션 버튼들 위젯
class ActionButtonsWidget extends StatelessWidget {
  final bool hasImages;
  final VoidCallback onTakePhoto;
  final VoidCallback onSelectFromGallery;
  final VoidCallback onRetake;
  final VoidCallback? onProceedNext;

  const ActionButtonsWidget({
    super.key,
    required this.hasImages,
    required this.onTakePhoto,
    required this.onSelectFromGallery,
    required this.onRetake,
    this.onProceedNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 사진이 없을 때만 카메라/갤러리 버튼 표시
          if (!hasImages) ...[
            Row(
              children: [
                // 카메라로 촬영 버튼
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTakePhoto,
                    icon: Icon(
                      Icons.camera_alt,
                      color: AppColors.orange.normal,
                      size: 18,
                    ),
                    label: Text(
                      '카메라로 촬영',
                      style: TextStyle(color: AppColors.orange.normal),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.orange.normal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 갤러리 선택 버튼
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelectFromGallery,
                    icon: Icon(
                      Icons.photo_library,
                      color: AppColors.orange.normal,
                      size: 18,
                    ),
                    label: Text(
                      '갤러리 선택',
                      style: TextStyle(color: AppColors.orange.normal),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.orange.normal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 하단 버튼들
          Row(
            children: [
              // 재촬영 버튼 (사진이 있을 때만)
              if (hasImages) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetake,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '재촬영',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 다음 단계 버튼
              Expanded(
                flex: hasImages ? 1 : 2,
                child: ElevatedButton(
                  onPressed: hasImages ? onProceedNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasImages
                        ? AppColors.primary.normal
                        : AppColors.black.light,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasImages ? '다음 단계' : '사진을 선택해주세요',
                    style: TextStyle(
                      color: hasImages
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
