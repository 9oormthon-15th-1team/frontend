import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../logging/app_logger.dart';

/// GPS 위치 서비스를 담당하는 클래스
class LocationService {
  /// 현재 위치 가져오기
  ///
  /// 위치 권한을 요청하고 GPS로부터 현재 위치를 가져옵니다.
  ///
  /// Returns: [Position] 현재 위치 정보
  /// Throws: [LocationServiceException] 위치를 가져올 수 없을 때
  static Future<Position> getCurrentLocation() async {
    try {
      // 위치 권한 요청
      final permission = await Permission.location.request();

      if (permission == PermissionStatus.denied) {
        throw LocationServiceException('위치 권한이 거부되었습니다');
      }

      if (permission == PermissionStatus.permanentlyDenied) {
        throw LocationServiceException('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요');
      }

      // GPS로부터 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      AppLogger.info('위치 가져오기 성공: ${position.latitude}, ${position.longitude}');
      return position;
    } on LocationServiceException {
      // 이미 처리된 예외는 그대로 전달
      rethrow;
    } catch (e) {
      AppLogger.error('위치 정보 획득 실패', error: e);
      throw LocationServiceException('위치 정보를 가져오는 중 오류가 발생했습니다');
    }
  }

  /// 위치 권한 상태 확인
  ///
  /// Returns: 현재 위치 권한 상태
  static Future<PermissionStatus> checkPermission() async {
    return await Permission.location.status;
  }

  /// 위치 서비스 활성화 여부 확인
  ///
  /// Returns: true if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 마지막 알려진 위치 가져오기 (캐시된 위치)
  ///
  /// Returns: [Position?] 마지막 위치 또는 null
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      AppLogger.warning('마지막 알려진 위치 가져오기 실패', error: e);
      return null;
    }
  }
}

/// 위치 서비스 관련 예외
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => message;
}
