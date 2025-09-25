import 'package:flutter/material.dart';
import 'package:frontend/core/theme/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/logging/app_logger.dart';
import 'components/empty_state_widget.dart';
import 'components/image_grid_widget.dart';
import 'components/action_buttons_widget.dart';

/// 포트홀 신고 bottom sheet 위젯
class PotholeReportBottomSheet extends StatefulWidget {
  const PotholeReportBottomSheet({super.key});

  @override
  State<PotholeReportBottomSheet> createState() =>
      _PotholeReportBottomSheetState();
}

class _PotholeReportBottomSheetState extends State<PotholeReportBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = []; // 선택된 이미지들을 저장할 리스트
  final int _maxImages = 6; // 최대 6장까지

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black.lightActive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('사진 촬영', style: AppTypography.titleLg),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // 진행률 표시
          const SizedBox(height: 20),

          // 선택된 이미지가 없을 때와 있을 때 다른 UI 표시
          Expanded(
            child: _selectedImages.isEmpty
                ? const EmptyStateWidget()
                : ImageGridWidget(
                    selectedImages: _selectedImages,
                    maxImages: _maxImages,
                    onAddImage: _showImagePickerOptions,
                    onRemoveImage: _removeImage,
                  ),
          ),

          // 버튼들
          ActionButtonsWidget(
            hasImages: _selectedImages.isNotEmpty,
            onTakePhoto: _takePhotoWithCamera,
            onSelectFromGallery: _selectFromGallery,
            onRetake: _showImagePickerOptions,
            onProceedNext: _proceedToNext,
          ),
        ],
      ),
    );
  }

  /// 이미지 제거
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 이미지 추가
  void _addImage(XFile image) {
    if (_selectedImages.length < _maxImages) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  /// 이미지 선택 옵션 표시
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.primary.normal,
                ),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.orange.normal,
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 카메라로 사진 촬영
  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        _addImage(photo);
        AppLogger.info('사진 촬영 완료: ${photo.path}');
      } else {
        AppLogger.info('사진 촬영 취소됨');
      }
    } catch (e) {
      AppLogger.error('카메라 촬영 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error.normal,
          ),
        );
      }
    }
  }

  /// 갤러리에서 사진 선택
  Future<void> _selectFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        _addImage(photo);
        AppLogger.info('갤러리에서 사진 선택 완료: ${photo.path}');
      } else {
        AppLogger.info('사진 선택 취소됨');
      }
    } catch (e) {
      AppLogger.error('갤러리에서 사진 선택 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('갤러리 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error.normal,
          ),
        );
      }
    }
  }

  /// 다음 단계로 진행
  void _proceedToNext() {
    if (_selectedImages.isNotEmpty) {
      Navigator.pop(context, _selectedImages); // 선택된 이미지들을 반환

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedImages.length}장의 사진이 선택되었습니다'),
          backgroundColor: AppColors.primary.normal,
        ),
      );

      // 포트홀 사진 선택 화면으로 이동
      context.go('/photo-selection');
      AppLogger.info('다음 단계로 진행: ${_selectedImages.length}장의 사진 선택됨');
    }
  }
}
