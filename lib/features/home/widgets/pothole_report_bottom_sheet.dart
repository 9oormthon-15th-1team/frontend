import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/logging/app_logger.dart';

/// 포트홀 신고 bottom sheet 위젯
class PotholeReportBottomSheet extends StatefulWidget {
  const PotholeReportBottomSheet({super.key});

  @override
  State<PotholeReportBottomSheet> createState() => _PotholeReportBottomSheetState();
}

class _PotholeReportBottomSheetState extends State<PotholeReportBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '사진 촬영',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // 진행률 표시
          _buildProgressIndicator(),

          const SizedBox(height: 40),

          // 카메라 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // 메인 텍스트
          const Text(
            '포트홀 사진을 촬영해주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          // 서브 텍스트
          const Text(
            '포트홀이 잘 보이도록 촬영해주세요.\n여러 장 촬영하면 더 정확한 신고가 가능합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),

          const Spacer(),

          // 버튼들
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 진행률 표시 위젯
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼들
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // 카메라로 촬영 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhotoWithCamera,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.orange,
                    size: 18,
                  ),
                  label: const Text(
                    '카메라로 촬영',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 갤러리 선택 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectFromGallery,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.orange,
                    size: 18,
                  ),
                  label: const Text(
                    '갤러리 선택',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 사진을 선택해주세요 버튼 (비활성화 상태)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // 비활성화
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '사진을 선택해주세요',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
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
        if (mounted) {
          Navigator.pop(context);
          AppLogger.info('사진 촬영 완료: ${photo.path}');

          // 사진 촬영 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진이 촬영되었습니다: ${photo.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 다음 단계로 이동 (추후 구현)
        // TODO: 포트홀 상세 정보 입력 페이지로 이동
      } else {
        AppLogger.info('사진 촬영 취소됨');
      }
    } catch (e) {
      AppLogger.error('카메라 촬영 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        if (mounted) {
          Navigator.pop(context);
          AppLogger.info('갤러리에서 사진 선택 완료: ${photo.path}');

          // 사진 선택 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진이 선택되었습니다: ${photo.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 다음 단계로 이동 (추후 구현)
        // TODO: 포트홀 상세 정보 입력 페이지로 이동
      } else {
        AppLogger.info('사진 선택 취소됨');
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      AppLogger.error('갤러리에서 사진 선택 실패', error: e);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('갤러리 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}