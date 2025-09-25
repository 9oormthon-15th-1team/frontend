import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/core/theme/design_system.dart';

/// 이미지 그리드 위젯
class ImageGridWidget extends StatelessWidget {
  final List<XFile> selectedImages;
  final int maxImages;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;

  const ImageGridWidget({
    super.key,
    required this.selectedImages,
    required this.maxImages,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "사진 촬영" 텍스트
          Text('포트홀 사진', style: AppTypography.titleMd),

          // 사진 그리드
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: maxImages,
              itemBuilder: (context, index) {
                if (index < selectedImages.length) {
                  // 선택된 이미지 표시
                  return _buildImageTile(selectedImages[index], index);
                } else {
                  // 빈 슬롯 표시
                  return _buildEmptyImageSlot();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 선택된 이미지 타일
  Widget _buildImageTile(XFile imageFile, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black.light),
      ),
      child: Stack(
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              File(imageFile.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 삭제 버튼
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.error.normal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.textOnError,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 이미지 슬롯
  Widget _buildEmptyImageSlot() {
    return GestureDetector(
      onTap: onAddImage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black.light,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black.lightActive),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text('사진', style: AppTypography.titleMd),
          ],
        ),
      ),
    );
  }
}
