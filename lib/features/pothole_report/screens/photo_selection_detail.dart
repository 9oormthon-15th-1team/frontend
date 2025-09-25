import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/design_system.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/logging/app_logger.dart';
import '../models/photo_selection_state.dart';
import '../widgets/image_picker_dialog.dart';
import '../widgets/photo_grid.dart';

class PhotoSelectionDetailScreen extends StatefulWidget {
  const PhotoSelectionDetailScreen({super.key});

  @override
  State<PhotoSelectionDetailScreen> createState() =>
      _PhotoSelectionDetailScreenState();
}

class _PhotoSelectionDetailScreenState
    extends State<PhotoSelectionDetailScreen> {
  PhotoSelectionState _photoState = PhotoSelectionState();
  final ImagePicker _imagePicker = ImagePicker();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isConsentChecked = false;
  bool _isPhoneVerified = false;
  bool _isVerificationSent = false;
  String _locationAddress = '위치를 가져오는 중...';

  @override
  void initState() {
    super.initState();
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
            _locationAddress =
                '위도: ${position.latitude.toStringAsFixed(6)}, 경도: ${position.longitude.toStringAsFixed(6)}';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationAddress = '위치 권한이 거부되었습니다.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationAddress = '위치를 가져올 수 없습니다.';
        });
      }
      AppLogger.error('위치 정보 획득 실패', error: e);
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

  /// 민원 제출
  Future<void> _submitReport() async {
    if (_isSubmitting ||
        !_photoState.hasImages ||
        !_isConsentChecked ||
        !_isPhoneVerified) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _submitPotholeReport();

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
    if (_photoState.hasImages) {
      try {
        final firstImage = _photoState.selectedImages.first;
        final bytes = await firstImage.readAsBytes();
        final imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // 여기에서 API 호출을 수행합니다.
        // 예시: await apiService.submitReport(imageBase64, _currentPosition, _descriptionController.text);
        AppLogger.info('민원 제출 데이터 준비 완료: 이미지 길이 ${imageBase64.length}');
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
          // 상단 영역 - 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48), // 좌측 공간 확보
              const Text(
                '민원 제출',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 위치 섹션
          _buildLocationSection(),
          const SizedBox(height: 16),

          // 네이버 지도 컨테이너
          _buildMapContainer(),
          const SizedBox(height: 24),

          // 사진 그리드
          PhotoGrid(
            state: _photoState,
            onTapSlot: _showImagePicker,
            onDeleteImage: _deleteImage,
          ),
          const SizedBox(height: 24),

          // 설명 입력란
          _buildDescriptionField(),
          const SizedBox(height: 24),

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
        const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
        const SizedBox(width: 8),
        const Text(
          '위치',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        // 사진 버튼들
        Row(
          children: [
            _buildPhotoButton('사진 1'),
            const SizedBox(width: 8),
            _buildPhotoButton('사진 2'),
          ],
        ),
      ],
    );
  }

  /// 사진 버튼 구축
  Widget _buildPhotoButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  /// 지도 컨테이너 구축
  Widget _buildMapContainer() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'Naver Map Slot',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _locationAddress,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 설명 입력 필드 구축
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: TextField(
            controller: _descriptionController,
            maxLines: 5,
            style: AppTypography.caption,
            decoration: InputDecoration(
              hintText: '내용을 직접 입력하여 신고할 기능입니다.',
              hintStyle: const TextStyle(color: Colors.grey),
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
              contentPadding: const EdgeInsets.all(12),
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
            const Text(
              '민원 제출에 동의합니다',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      const SizedBox(height: 16),

      // 전화번호 입력
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '전화번호를 입력해주세요.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('인증번호'),
          ),
        ],
      ),

      // 인증번호 입력 (발송 후에만 표시)
      if (_isVerificationSent) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _verificationCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '인증 번호',
                  hintText: '인증 번호를 입력해주세요.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isPhoneVerified ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ],

      // 인증 완료 메시지
      if (_isPhoneVerified) ...[
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text(
              '인증되었습니다.',
              style: TextStyle(
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
    final canSubmit =
        _photoState.hasImages &&
        _isConsentChecked &&
        _isPhoneVerified &&
        !_isSubmitting;

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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? _submitReport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? const Color(0xFFFF6B35) // 주황색 #FF6B35
                : Colors.grey[300],
            foregroundColor: canSubmit ? Colors.white : Colors.grey[500],
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
