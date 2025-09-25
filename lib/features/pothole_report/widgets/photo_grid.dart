import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo_selection_state.dart';

/// 3x2 사진 그리드 위젯
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.state,
    required this.onTapSlot,
    required this.onDeleteImage,
  });

  final PhotoSelectionState state;
  final VoidCallback onTapSlot;
  final Function(int index) onDeleteImage;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: state.maxImages,
      itemBuilder: (context, index) {
        return PhotoSlot(
          index: index,
          image: state.getImageAt(index),
          hasImage: state.hasImageAt(index),
          onTap: () => _handleSlotTap(context, index),
          onDelete: () => _handleDelete(context, index),
        );
      },
    );
  }

  void _handleSlotTap(BuildContext context, int index) {
    // 해당 슬롯에 이미지가 있으면 이미지 뷰어 표시 (선택사항)
    if (state.hasImageAt(index)) {
      _showImageViewer(context, index);
    } else {
      // 빈 슬롯이면 이미지 선택
      onTapSlot();
    }
  }

  void _handleDelete(BuildContext context, int index) {
    // 햅틱 피드백
    HapticFeedback.lightImpact();
    onDeleteImage(index);

    // 삭제 피드백
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사진이 삭제되었습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showImageViewer(BuildContext context, int index) {
    final image = state.getImageAt(index);
    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // 이미지
            Center(
              child: InteractiveViewer(
                child: Image.file(File(image.path), fit: BoxFit.contain),
              ),
            ),
            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 개별 사진 슬롯 위젯
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    super.key,
    required this.index,
    required this.hasImage,
    this.image,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final bool hasImage;
  final XFile? image;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : const Color(0xFFF5F5F5),
          border: Border.all(
            color: hasImage ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: hasImage ? _buildFilledSlot() : _buildEmptySlot(),
      ),
    );
  }

  /// 빈 슬롯 UI
  Widget _buildEmptySlot() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 24, color: Colors.grey[500]),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 채워진 슬롯 UI
  Widget _buildFilledSlot() {
    return Stack(
      children: [
        // 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.expand(
            child: image != null
                ? Image.file(File(image!.path), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[500]),
                  ),
          ),
        ),

        // 삭제 버튼
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
