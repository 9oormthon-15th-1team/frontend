import 'package:flutter/material.dart';
import 'package:frontend/core/theme/design_system.dart';

/// 빈 상태 위젯 (사진이 선택되지 않았을 때)
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 카메라 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.normal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.camera_alt,
            color: AppColors.textOnPrimary,
            size: 40,
          ),
        ),

        const SizedBox(height: 24),

        // 메인 텍스트
        Text('사진을 추가해주세요.', style: AppTypography.bodySm),

        const SizedBox(height: 12),
      ],
    );
  }
}
