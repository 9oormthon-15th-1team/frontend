import 'package:flutter/material.dart';
import 'package:porthole_in_jeju/core/theme/design_system.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/services/location/location_service.dart';
import '../../../core/services/logging/app_logger.dart';
import '../models/photo_selection_state.dart';
import '../services/image_picker_service.dart';
import '../services/pothole_report_submission_service.dart';
import '../widgets/image_picker_dialog.dart';
import '../widgets/photo_grid.dart';

class PhotoSelectionDetailScreen extends StatefulWidget {
  final PhotoSelectionState? initialPhotoState;

  const PhotoSelectionDetailScreen({super.key, this.initialPhotoState});

  @override
  State<PhotoSelectionDetailScreen> createState() =>
      _PhotoSelectionDetailScreenState();
}

class _PhotoSelectionDetailScreenState
    extends State<PhotoSelectionDetailScreen> {
  late PhotoSelectionState _photoState;
  Position? _currentPosition;
  NaverMapController? _naverMapController;
  bool _isLoading = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _photoState = widget.initialPhotoState ?? PhotoSelectionState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateMapLocation();
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
      AppLogger.error('위치 정보 획득 실패', error: e);
    }
  }

  Future<void> _updateMapLocation() async {
    if (_currentPosition == null || _naverMapController == null) return;

    final target = NLatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    try {
      await _naverMapController!.updateCamera(
        NCameraUpdate.withParams(target: target, zoom: 16),
      );
      _naverMapController!.setLocationTrackingMode(
        NLocationTrackingMode.follow,
      );
      final overlay = _naverMapController!.getLocationOverlay();
      overlay.setIsVisible(true);
    } catch (e) {
      AppLogger.warning('지도 이동 실패', error: e);
    }
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
      final allowMultiple = _photoState.canAddMore &&
          _photoState.maxImages - _photoState.selectedImages.length > 1;

      final images = await ImagePickerService.pickImages(
        source: result,
        allowMultiple: allowMultiple,
      );

      if (images.isNotEmpty) {
        setState(() {
          _photoState = _photoState.addImages(images);
        });
      }
    } on ImagePickerException catch (e) {
      _showErrorSnackBar(e.toString());
    } catch (e) {
      _showErrorSnackBar('이미지 선택 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 이미지 삭제
  void _deleteImage(int index) {
    setState(() {
      _photoState = _photoState.removeImage(index);
    });
    AppLogger.info('이미지 삭제: index $index');
  }

  /// 민원 제출
  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _submitPotholeReport();

      if (!mounted) return;

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('민원 제출이 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      // 모든 바텀시트와 다이얼로그를 닫고 홈으로 돌아가기
      Navigator.of(context).popUntil((route) => route.isFirst);

      AppLogger.info('민원 제출 완료');
    } catch (e) {
      AppLogger.error('민원 제출 실패', error: e);
      _showErrorSnackBar('제출 중 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitPotholeReport() async {
    // 위치 정보 확인
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        throw Exception('위치 정보를 가져올 수 없습니다');
      }
    }

    // 이미지 검증
    if (_photoState.hasImages) {
      final validationError = await PotholeReportSubmissionService.validateImages(
        _photoState.selectedImages,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }
    }

    // 신고 제출 (서비스로 위임)
    await PotholeReportSubmissionService.submitReport(
      position: _currentPosition!,
      description: _descriptionController.text,
      images: _photoState.hasImages ? _photoState.selectedImages : null,
    );
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 메인 콘텐츠
            Expanded(child: _buildMainContent()),

            // 하단 버튼 영역
            _buildBottomButtons(),
          ],
        ),
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    '포트홀 신고하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 사진 그리드
          PhotoGrid(
            state: _photoState,
            onTapSlot: _showImagePicker,
            onDeleteImage: _deleteImage,
          ),

          const SizedBox(height: 16),

          // 위치 섹션
          _buildLocationSection(),
          const SizedBox(height: 8),

          // 네이버 지도 컨테이너
          _buildMapContainer(),
          const SizedBox(height: 16),

          // 설명 입력란
          _buildDescriptionField(),
        ],
      ),
    );
  }

  /// 위치 섹션 구축
  Widget _buildLocationSection() {
    return Row(
      children: [
        Text(
          '위치',
          style: AppTypography.bodyDefault.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMapContainer() {
    return SizedBox(
      height: 200,
      child: NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(
              _currentPosition?.latitude ?? 37.5665, // 기본 서울 좌표
              _currentPosition?.longitude ?? 126.9780,
            ),
            zoom: 15,
          ),
          locationButtonEnable: true,
        ),
        onMapReady: (controller) {
          _naverMapController = controller;
          _updateMapLocation();
        },
      ),
    );
  }

  /// 설명 입력 필드 구축
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설명',
          style: AppTypography.bodyDefault.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: TextField(
            controller: _descriptionController,
            maxLines: 20,
            style: AppTypography.caption,
            decoration: InputDecoration(
              hintText: '내용을 적지 않아도 신고가 가능합니다.',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF6B35)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 하단 버튼 영역
  Widget _buildBottomButtons() {
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSubmitting
                ? Colors.grey[300]
                : const Color(0xFFFF6B35), // 주황색 #FF6B35
            foregroundColor: _isSubmitting ? Colors.grey[500] : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[500],
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
