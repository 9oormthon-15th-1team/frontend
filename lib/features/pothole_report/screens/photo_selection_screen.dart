import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/pothole_report.dart';
import '../../../core/services/api/pothole_report_service.dart';
import '../../../core/services/logging/app_logger.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../models/photo_selection_state.dart';
import '../widgets/camera_area.dart';
import '../widgets/image_picker_dialog.dart';
import '../widgets/photo_grid.dart';

/// 포트홀 사진 촬영/선택 화면
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
    _getCurrentLocation();
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestResult = await Geolocator.requestPermission();
        if (requestResult == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      setState(() {
        _currentPosition = position;
      });

      AppLogger.info('현재 위치 가져오기 완료: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      AppLogger.error('현재 위치 가져오기 실패', error: e);
      _showLocationErrorDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 필요'),
        content: const Text('포트홀 위치를 정확히 기록하기 위해 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 오류'),
        content: const Text('현재 위치를 가져올 수 없습니다. 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _getCurrentLocation();
            },
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }

  /// 이미지 선택 다이얼로그 표시
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
      if (_photoState.canAddMore && _photoState.maxImages - _photoState.selectedImages.length > 1) {
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

  /// 모든 이미지 삭제 (재촬영)
  void _retakePhotos() {
    setState(() {
      _photoState = _photoState.clearImages();
    });

    // 햅틱 피드백
    HapticFeedback.mediumImpact();

    AppLogger.info('모든 이미지 삭제');

    // 바로 이미지 선택 다이얼로그 표시
    _showImagePicker();
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
      Navigator.of(context).pop();

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

  /// 실제 포트홀 신고 API 제출
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

    final report = PotholeReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '포트홀 신고',
      description: '모바일 앱을 통한 포트홀 신고 (${_photoState.selectedImages.length}장의 사진)',
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      createdAt: DateTime.now(),
      imageBase64: imageBase64,
      status: 'pending',
    );

    await PotholeReportService.pushReport(report);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('포트홀 신고'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 상단 지도 영역
          _buildMapArea(),

          // 메인 콘텐츠
          Expanded(
            child: _buildMainContent(),
          ),

          // 하단 버튼 영역
          _buildBottomButtons(),
        ],
      ),
    );
  }

  /// 상단 지도 영역
  Widget _buildMapArea() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: double.infinity,
      color: Colors.grey[200],
      child: _currentPosition != null
          ? _buildNaverMap()
          : _buildMapPlaceholder(),
    );
  }

  /// 네이버 맵
  Widget _buildNaverMap() {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 16,
        ),
        locale: const Locale('ko'),
        mapType: NMapType.basic,
        scrollGesturesEnable: false,
        zoomGesturesEnable: false,
        tiltGesturesEnable: false,
        rotationGesturesEnable: false,
      ),
      onMapReady: (controller) {
        // 현재 위치에 마커 추가
        _addCurrentLocationMarker(controller);
      },
    );
  }

  /// 현재 위치 마커 추가
  void _addCurrentLocationMarker(NaverMapController controller) async {
    final marker = NMarker(
      id: 'current_location',
      position: NLatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
    );

    await controller.addOverlay(marker);
  }

  /// 지도 플레이스홀더
  Widget _buildMapPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '위치 정보를 가져오는 중...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
      child: Row(
        children: [
          // 재촬영 버튼
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _photoState.hasImages && !_isLoading ? _retakePhotos : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: _photoState.hasImages ? Colors.grey[400]! : Colors.grey[300]!,
                ),
              ),
              child: const Text(
                '재촬영',
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
            flex: 3,
            child: ElevatedButton(
              onPressed: _photoState.hasImages && !_isSubmitting ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange.normal,
                foregroundColor: Colors.white,
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
                      '추가 작성',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}