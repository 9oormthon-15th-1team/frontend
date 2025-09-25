import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens/app_colors.dart';
import '../models/pothole_info.dart';

/// 포트홀 상세 정보를 표시하는 전체 화면 페이지
class PotholeDetailPage extends StatefulWidget {
  const PotholeDetailPage({super.key, required this.potholeInfo});

  final PotholeInfo potholeInfo;

  @override
  State<PotholeDetailPage> createState() => _PotholeDetailPageState();
}

class _PotholeDetailPageState extends State<PotholeDetailPage> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '포트홀 상세정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReportSummary(),
            const SizedBox(height: 20),
            _buildImageSection(context),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 12),
            _buildDescriptionCard(),
            _buildConditionalComplaintNumber(),
            const SizedBox(height: 20),
            const SizedBox(height: 12),
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildImageSection(BuildContext context) {
    if (_images.isEmpty) {
      return _buildImagePlaceholderContainer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_shouldUseSlider) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
            child: Row(
              children: [
                for (int i = 0; i < _images.length; i++) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageCard(context, _images[i], i),
                    ),
                  ),
                  if (i != _images.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholderContainer() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
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
        : '도로에 깊은 포트홀이 생겨 차량이 지나가기 위험한 상황입니다.\\n빠른 보수 작업을 부탁드립니다.';

    return Container(
      height: 200, // 고정 높이 추가
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
    final isInProgress = widget.potholeInfo.status == 'in_progress';
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
}
