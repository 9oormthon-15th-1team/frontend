import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/pothole_status.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../models/pothole_info.dart';

/// 포트홀 상세 정보를 표시하는 bottom sheet
class PotholeDetailBottomSheet extends StatefulWidget {
  const PotholeDetailBottomSheet({super.key, required this.potholeInfo});

  final PotholeInfo potholeInfo;

  static Future<void> show(BuildContext context, PotholeInfo potholeInfo) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      builder: (context) => PotholeDetailBottomSheet(potholeInfo: potholeInfo),
    );
  }

  @override
  State<PotholeDetailBottomSheet> createState() =>
      _PotholeDetailBottomSheetState();
}

class _PotholeDetailBottomSheetState extends State<PotholeDetailBottomSheet> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  List<String> get _images => widget.potholeInfo.displayImages;

  bool get _shouldUseSlider => _images.length >= 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomSafe),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        '포트홀 상세정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildReportSummary(),
                    const SizedBox(height: 20),
                    _buildImageSection(context),
                    const SizedBox(height: 16),
                    _buildAddressCard(),
                    const SizedBox(height: 12),
                    _buildDescriptionCard(),
                    _buildConditionalComplaintNumber(),
                    const SizedBox(height: 20),
                    _buildConditionalButtons(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummary() {
    final formatter = DateFormat('yyyy.MM.dd. HH:mm');
    final info = widget.potholeInfo;
    final additionalText = info.additionalReportCount > 0
        ? ' (${info.reportCount})'
        : '';

    Widget buildRow(String label, String value) {
      return Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    final rows = <Widget>[
      buildRow('최초 신고 일자', formatter.format(info.firstReportDate)),
      const SizedBox(height: 6),
      buildRow(
        '추가 신고 일자',
        '${formatter.format(info.latestReportDate)}$additionalText',
      ),
    ];

    // rows
    //   ..add(const SizedBox(height: 6))
    //   ..add(
    //     buildRow(
    //       '민원번호',
    //       (info.complaintId == null || info.complaintId!.isEmpty)
    //           ? '정보 없음'
    //           : info.complaintId!,
    //     ),
    //   );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildImageSection(BuildContext context) {
    if (_images.isEmpty) {
      return _buildImagePlaceholderContainer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text(
        //   '이미지 (${_images.length}/6)',
        //   style: TextStyle(
        //     fontSize: 14,
        //     color: Colors.grey[600],
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        // const SizedBox(height: 12),
        if (_shouldUseSlider) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildImageCard(context, _images[index], index);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPageIndicator(_images.length),
        ] else
          Row(
            children: [
              for (int i = 0; i < _images.length; i++) ...[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildImageCard(context, _images[i], i),
                    ),
                  ),
                ),
                if (i != _images.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildImagePlaceholderContainer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 40),
    );
  }

  Widget _buildImageCard(BuildContext context, String imagePath, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showImageViewer(context, _images, index),
      child: _buildImageWidget(imagePath),
    );
  }

  Widget _buildPageIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == _currentImageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 18 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.orange.normal : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildAddressCard() {
    final address = widget.potholeInfo.address.isNotEmpty
        ? widget.potholeInfo.address
        : '주소 정보가 제공되지 않았습니다.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, size: 20, color: AppColors.orange.normal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final description = widget.potholeInfo.description.isNotEmpty
        ? widget.potholeInfo.description
        : '도로에 깊은 포트홀이 생겨 차량이 지나가기 위험한 상황입니다.\n빠른 보수 작업을 부탁드립니다.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
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
      } catch (_) {
        return _buildImagePlaceholder();
      }
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
    );
  }

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

  /// 조건부 민원번호 표시
  Widget _buildConditionalComplaintNumber() {
    final isInProgress = widget.potholeInfo.status == PotholeStatus.caution;
    final complaintId = widget.potholeInfo.complaintId?.isNotEmpty == true
        ? widget.potholeInfo.complaintId!
        : null;

    if (isInProgress && complaintId != null) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '민원번호: $complaintId',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// 조건부 버튼들
  Widget _buildConditionalButtons() {
    final isInProgress = widget.potholeInfo.status == PotholeStatus.caution;

    if (isInProgress) {
      // 처리중일 때는 "처리중" 버튼만 표시
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null, // 비활성화
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text(
            '처리중',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      // 처리중이 아닐 때는 "나도 봤수다!" 버튼 표시
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onVoteButtonPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722), // 주황색
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text(
            '나도 봤수다!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  /// 투표 버튼 클릭 처리
  void _onVoteButtonPressed() {
    // 투표 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('투표가 등록되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
