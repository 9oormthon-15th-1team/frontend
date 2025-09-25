import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/pothole_report/screens/photo_selection_detail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/logging/app_logger.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../models/photo_selection_state.dart';
import '../widgets/camera_area.dart';
import '../widgets/image_picker_dialog.dart';
import '../widgets/photo_grid.dart';

class PhotoSelectionScreen extends StatefulWidget {
  const PhotoSelectionScreen({super.key});

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  PhotoSelectionState _photoState = PhotoSelectionState();
  final ImagePicker _imagePicker = ImagePicker();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showImagePicker() async {
    if (_isLoading) return;

    final result = await ImagePickerDialog.show(
      context,
      allowMultiple: _photoState.canAddMore,
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (result == 'camera') {
        await _pickFromCamera();
      } else if (result == 'gallery') {
        await _pickFromGallery();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 카메라에서 이미지 선택
  Future<void> _pickFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _photoState = _photoState.addImage(image);
        });

        // 햅틱 피드백
        HapticFeedback.selectionClick();

        AppLogger.info('카메라에서 이미지 선택: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('카메라 이미지 선택 실패', error: e);
      _showErrorSnackBar('카메라 사용 중 오류가 발생했습니다');
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickFromGallery() async {
    try {
      if (_photoState.canAddMore &&
          _photoState.maxImages - _photoState.selectedImages.length > 1) {
        // 여러 장 선택 가능
        final images = await _imagePicker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (images.isNotEmpty) {
          setState(() {
            _photoState = _photoState.addImages(images);
          });

          // 햅틱 피드백
          HapticFeedback.selectionClick();

          AppLogger.info('갤러리에서 이미지 선택: ${images.length}장');
        }
      } else {
        // 1장만 선택
        final image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          setState(() {
            _photoState = _photoState.addImage(image);
          });

          // 햅틱 피드백
          HapticFeedback.selectionClick();

          AppLogger.info('갤러리에서 이미지 선택: ${image.path}');
        }
      }
    } catch (e) {
      AppLogger.error('갤러리 이미지 선택 실패', error: e);
      _showErrorSnackBar('갤러리 접근 중 오류가 발생했습니다');
    }
  }

  /// 이미지 삭제
  void _deleteImage(int index) {
    setState(() {
      _photoState = _photoState.removeImage(index);
    });
    AppLogger.info('이미지 삭제: index $index');
  }

  /// 포트홀 신고 제출
  Future<void> _submitReport() async {
    if (_isSubmitting || !_photoState.hasImages) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _submitPotholeReport();

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('포트홀 신고가 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      // 이전 화면으로 돌아가기

      AppLogger.info('포트홀 신고 제출 완료');
    } catch (e) {
      AppLogger.error('포트홀 신고 제출 실패', error: e);
      _showErrorSnackBar('신고 제출 중 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitPotholeReport() async {
    if (_currentPosition == null) {
      throw Exception('위치 정보를 가져올 수 없습니다');
    }

    // 이미지를 Base64로 인코딩 (첫 번째 이미지만 사용, 여러 이미지 지원은 추후 구현)
    String imageBase64 = '';
    if (_photoState.hasImages) {
      try {
        final firstImage = _photoState.selectedImages.first;
        final bytes = await firstImage.readAsBytes();
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (e) {
        AppLogger.error('이미지 인코딩 실패', error: e);
        throw Exception('이미지 처리 중 오류가 발생했습니다');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // 메인 콘텐츠
          Expanded(child: _buildMainContent()),

          // 하단 버튼 영역
          _buildBottomButtons(),
        ],
      ),
    );
  }

  /// 상단 지도 영역

  /// 메인 콘텐츠
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Center(
            child: Text(
              '포트홀 사진',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // 카메라 영역
          CameraArea(
            hasImages: _photoState.hasImages,
            latestImage: _photoState.latestImage,
            imageCountText: _photoState.imageCountText,
            onTap: _showImagePicker,
          ),
          const SizedBox(height: 24),

          // 사진 그리드
          PhotoGrid(
            state: _photoState,
            onTapSlot: _showImagePicker,
            onDeleteImage: _deleteImage,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 하단 버튼 영역
  Widget _buildBottomButtons() {
    final hasImages = _photoState.hasImages;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 제출 버튼
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: hasImages && !_isSubmitting ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasImages
                    ? AppColors.orange.normal
                    : Colors.grey[300],
                foregroundColor: hasImages ? Colors.white : Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '제출',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // 추가 작성 버튼
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: _showSelectionDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.orange.normal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '추가 작성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectionDetail() {
    // 먼저 바텀시트를 닫고
    Navigator.of(context).pop();

    // 닫힌 후에 새로운 화면으로 이동
    Future.delayed(Duration.zero, () {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true, // 전체 화면 다이얼로그처럼 표시
          builder: (context) => const PhotoSelectionDetailScreen(),
        ),
      );
    });
  }
}
