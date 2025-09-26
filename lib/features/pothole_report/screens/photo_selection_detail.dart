import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/design_system.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/services/logging/app_logger.dart';
import '../../../core/services/api/pothole_api_service.dart';
import '../models/photo_selection_state.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  Position? _currentPosition;
  NaverMapController? _naverMapController;
  bool _isLoading = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isConsentChecked = false;
  bool _isPhoneVerified = false;
  bool _isVerificationSent = false;

  @override
  void initState() {
    super.initState();
    _photoState = widget.initialPhotoState ?? PhotoSelectionState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission == PermissionStatus.granted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _updateMapLocation();
        }
      } else {
        if (mounted) {
          setState(() {});
        }
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

  Future<void> _sendVerificationCode() async {
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar('전화번호를 입력해주세요.');
      return;
    }

    // 실제로는 SMS API를 호출합니다.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isVerificationSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호가 발송되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _verifyCode() {
    if (_verificationCodeController.text.isEmpty) {
      _showErrorSnackBar('인증번호를 입력해주세요.');
      return;
    }

    // 실제로는 서버에서 인증번호를 검증합니다.
    // 여기서는 시뮬레이션을 위해 임의의 조건을 사용합니다.
    if (_verificationCodeController.text == '1234') {
      setState(() {
        _isPhoneVerified = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _showErrorSnackBar('잘못된 인증번호입니다.');
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

      // 이전 화면으로 돌아가기
      Navigator.of(context).pop();

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
    try {
      if (_currentPosition == null) {
        throw Exception('위치 정보가 없습니다');
      }

      // XFile을 File로 변환
      List<File>? imageFiles;
      if (_photoState.hasImages) {
        imageFiles = [];
        for (final xFile in _photoState.selectedImages) {
          imageFiles.add(File(xFile.path));
        }
      }

      AppLogger.info('민원 제출 데이터 준비 완료');

      // PotholeApiService를 사용하여 API 호출
      final responseData = await PotholeApiService.reportPothole(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        images: imageFiles,
      );

      AppLogger.info('민원 제출 API 성공: ${responseData.toString()}');
    } catch (e) {
      AppLogger.error('민원 제출 처리 실패', error: e);
      rethrow;
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
          const SizedBox(height: 8),

          // 동의 및 인증 섹션
          _buildConsentSection(),
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
            color: AppColors.textSecondary, // 원하는 그레이 색상
          ),
        ),
        // const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
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
            color: AppColors.textSecondary, // 원하는 그레이 색상
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: TextField(
            controller: _descriptionController,
            maxLines: 20, // maxLines 제거
            style: AppTypography.caption,
            decoration: InputDecoration(
              hintText: '내용을 적지 않아도 신고가 가능합니다.',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, // 좌우 패딩
                vertical: 24, // 위아래 패딩
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

  /// 동의 및 인증 섹션 구축
  Widget _buildConsentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 민원 제출 동의
        Row(
          children: [
            Text('민원제출 동의', style: AppTypography.bodySm.copyWith()),
            Checkbox(
              value: _isConsentChecked,
              onChanged: (value) {
                setState(() {
                  _isConsentChecked = value ?? false;
                  if (!_isConsentChecked) {
                    _isPhoneVerified = false;
                    _isVerificationSent = false;
                    _phoneController.clear();
                    _verificationCodeController.clear();
                  }
                });
              },
              activeColor: const Color(0xFFFF6B35),
            ),
          ],
        ),

        // 휴대전화 인증 (동의 시에만 표시)
        if (_isConsentChecked) ..._buildPhoneVerificationSection(),
      ],
    );
  }

  /// 휴대전화 인증 섹션 구축
  List<Widget> _buildPhoneVerificationSection() {
    return [
      // 전화번호 입력
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '전화번호를 입력해주세요.',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12, // 여기서 크기 조절
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('인증'),
            ),
          ),
        ],
      ),

      // 인증번호 입력 (발송 후에만 표시)
      if (_isVerificationSent) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _verificationCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '인증번호를 입력해주세요.',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12, // 여기서 크기 조절
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isPhoneVerified ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPhoneVerified
                      ? Colors.grey[300]
                      : const Color(0xFFFF6B35),
                  foregroundColor: _isPhoneVerified
                      ? Colors.grey[500]
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ],

      // 인증 완료 메시지
      if (_isPhoneVerified) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              '인증되었습니다.',
              style: AppTypography.bodyDefault.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ];
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
