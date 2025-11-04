import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api/pothole_api_service.dart';
import '../../../core/services/logging/app_logger.dart';

/// 포트홀 신고 제출을 담당하는 서비스
class PotholeReportSubmissionService {
  /// 포트홀 신고 제출
  ///
  /// [position] GPS 위치 정보
  /// [description] 신고 설명 (선택)
  /// [images] 첨부 이미지 목록
  ///
  /// Returns: API 응답 데이터
  /// Throws: Exception if submission fails
  static Future<Map<String, dynamic>> submitReport({
    required Position position,
    String? description,
    List<XFile>? images,
  }) async {
    AppLogger.info('포트홀 신고 제출 시작');
    AppLogger.info('위치: lat=${position.latitude}, lng=${position.longitude}');
    AppLogger.info('이미지 개수: ${images?.length ?? 0}');

    try {
      // XFile을 File로 변환
      List<File>? imageFiles;
      if (images != null && images.isNotEmpty) {
        imageFiles = [];
        for (final xFile in images) {
          imageFiles.add(File(xFile.path));
          final fileSize = await xFile.length();
          AppLogger.info('이미지 파일: ${xFile.path} (크기: $fileSize bytes)');
        }
      }

      // API 호출
      final responseData = await PotholeApiService.reportPothole(
        latitude: position.latitude,
        longitude: position.longitude,
        description: _getDescription(description),
        images: imageFiles,
      );

      AppLogger.info('포트홀 신고 API 성공: $responseData');
      return responseData;
    } catch (e) {
      AppLogger.error('포트홀 신고 API 실패', error: e);
      rethrow;
    }
  }

  /// 설명 텍스트 정리
  static String _getDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return '포트홀 신고';
    }
    return description.trim();
  }

  /// 이미지 파일 검증
  ///
  /// 이미지가 유효한지 확인하고 에러 메시지를 반환합니다.
  /// Returns: null if valid, error message if invalid
  static Future<String?> validateImages(List<XFile> images) async {
    if (images.isEmpty) {
      return null; // 이미지가 없어도 제출 가능
    }

    for (final image in images) {
      try {
        final file = File(image.path);
        if (!await file.exists()) {
          return '일부 이미지 파일을 찾을 수 없습니다';
        }

        final fileSize = await file.length();
        // 10MB 제한
        if (fileSize > 10 * 1024 * 1024) {
          return '이미지 크기는 10MB를 초과할 수 없습니다';
        }
      } catch (e) {
        AppLogger.error('이미지 검증 실패', error: e);
        return '이미지 파일 검증 중 오류가 발생했습니다';
      }
    }

    return null;
  }
}
