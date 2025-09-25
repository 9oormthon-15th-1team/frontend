import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens/app_colors.dart';
import '../models/pothole_info.dart';

/// 포트홀 상세 정보를 표시하는 bottom sheet
class PotholeDetailBottomSheet extends StatelessWidget {
  const PotholeDetailBottomSheet({super.key, required this.potholeInfo});

  final PotholeInfo potholeInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 콘텐츠
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 (사진 포함)
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // 위치 정보
                  _buildLocationSection(),
                  const SizedBox(height: 16),

                  // 설명
                  _buildDescriptionSection(),
                  const SizedBox(height: 20),

                  // 하단 안전 영역
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 헤더 (제목 + 사진 + 날짜 + 상태)
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '포트홀 상세정보',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),

        // 사진 섹션을 헤더에 포함
        if (potholeInfo.images.isNotEmpty) ...[
          _buildPhotosSection(),
          const SizedBox(height: 20),
        ],

        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              DateFormat('yyyy.MM.dd. HH:mm').format(potholeInfo.createdAt),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  /// 사진 섹션
  Widget _buildPhotosSection() {
    final displayImages = potholeInfo.displayImages;

    if (displayImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
              '${potholeInfo.images.length}장',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPhotoGrid(displayImages),
      ],
    );
  }

  /// 사진 그리드 (최대 6개)
  Widget _buildPhotoGrid(List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length > 6 ? 6 : images.length,
      itemBuilder: (context, index) {
        final isLastItem = index == 5 && images.length > 6;

        return GestureDetector(
          onTap: () => _showImageViewer(context, images, index),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(images[index]),
                ),
              ),
              // +N 더 표시
              if (isLastItem)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Text(
                      '+${potholeInfo.additionalImageCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 이미지 위젯 생성
  Widget _buildImageWidget(String imagePath) {
    // Base64 이미지인 경우
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64.decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        );
      } catch (e) {
        return _buildImagePlaceholder();
      }
    }

    // 네트워크 이미지인 경우
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    // 로컬 파일인 경우
    return Image.asset(
      imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  /// 이미지 플레이스홀더
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
    );
  }

  /// 이미지 뷰어 표시
  void _showImageViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: _buildImageWidget(images[index]),
                  ),
                );
              },
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
            // 이미지 카운터
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${initialIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 위치 정보 섹션
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 20, color: AppColors.orange.normal),
            const SizedBox(width: 8),
            const Text(
              '위치 정보',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          potholeInfo.address.isNotEmpty
              ? potholeInfo.address
              : '제주특별시도 제주시 이도이동',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  /// 설명 섹션
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          potholeInfo.description.isNotEmpty
              ? potholeInfo.description
              : '도로에 깊은 포트홀 발견 지나가기 위험한 상황입니다.\n특히 밤에는 잘 보이지 않아 사고 위험이 있습니다.\n빠른 보수 작업이 필요합니다.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// bottom sheet 표시 정적 메서드
  static Future<void> show(BuildContext context, PotholeInfo potholeInfo) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => PotholeDetailBottomSheet(potholeInfo: potholeInfo),
    );
  }
}
