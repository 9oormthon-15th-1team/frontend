import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/logging/app_logger.dart';

/// 이미지 선택을 담당하는 서비스
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// 카메라에서 이미지 선택
  ///
  /// Returns: [XFile?] 선택된 이미지 파일 또는 null
  /// Throws: [ImagePickerException] 선택 실패 시
  static Future<XFile?> pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // 햅틱 피드백
        HapticFeedback.selectionClick();
        AppLogger.info('카메라에서 이미지 선택: ${image.path}');
      }

      return image;
    } catch (e) {
      AppLogger.error('카메라 이미지 선택 실패', error: e);
      throw ImagePickerException('카메라 사용 중 오류가 발생했습니다');
    }
  }

  /// 갤러리에서 단일 이미지 선택
  ///
  /// Returns: [XFile?] 선택된 이미지 파일 또는 null
  /// Throws: [ImagePickerException] 선택 실패 시
  static Future<XFile?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // 햅틱 피드백
        HapticFeedback.selectionClick();
        AppLogger.info('갤러리에서 이미지 선택: ${image.path}');
      }

      return image;
    } catch (e) {
      AppLogger.error('갤러리 이미지 선택 실패', error: e);
      throw ImagePickerException('갤러리 접근 중 오류가 발생했습니다');
    }
  }

  /// 갤러리에서 여러 이미지 선택
  ///
  /// Returns: [List<XFile>] 선택된 이미지 파일 목록
  /// Throws: [ImagePickerException] 선택 실패 시
  static Future<List<XFile>> pickMultipleFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty) {
        // 햅틱 피드백
        HapticFeedback.selectionClick();
        AppLogger.info('갤러리에서 이미지 선택: ${images.length}장');
      }

      return images;
    } catch (e) {
      AppLogger.error('갤러리 다중 이미지 선택 실패', error: e);
      throw ImagePickerException('갤러리 접근 중 오류가 발생했습니다');
    }
  }

  /// 이미지 소스 선택 후 이미지 가져오기
  ///
  /// [source] 이미지 소스 ('camera' 또는 'gallery')
  /// [allowMultiple] 여러 장 선택 허용 여부 (갤러리만 해당)
  ///
  /// Returns: 선택된 이미지 목록
  /// Throws: [ImagePickerException] 선택 실패 시
  static Future<List<XFile>> pickImages({
    required String source,
    bool allowMultiple = false,
  }) async {
    if (source == 'camera') {
      final image = await pickFromCamera();
      return image != null ? [image] : [];
    } else if (source == 'gallery') {
      if (allowMultiple) {
        return await pickMultipleFromGallery();
      } else {
        final image = await pickFromGallery();
        return image != null ? [image] : [];
      }
    } else {
      throw ImagePickerException('알 수 없는 이미지 소스: $source');
    }
  }
}

/// 이미지 선택 관련 예외
class ImagePickerException implements Exception {
  final String message;

  ImagePickerException(this.message);

  @override
  String toString() => message;
}
