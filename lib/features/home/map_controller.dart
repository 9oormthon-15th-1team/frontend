import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/services/logging/app_logger.dart';

/// 네이버 맵 관련 비즈니스 로직을 담당하는 컨트롤러
class MapController {
  NaverMapController? _mapController;
  final ValueNotifier<bool> _isMapReady = ValueNotifier<bool>(false);
  final ValueNotifier<NLatLng> _currentPosition = ValueNotifier<NLatLng>(
    const NLatLng(33.4996213, 126.5311884), // 제주시 기본 위치
  );
  final ValueNotifier<String> _currentAddress = ValueNotifier<String>(
    '위치 로딩 중...',
  );

  /// 맵 준비 상태 notifier
  ValueNotifier<bool> get isMapReadyNotifier => _isMapReady;

  /// 현재 위치 notifier
  ValueNotifier<NLatLng> get currentPositionNotifier => _currentPosition;

  /// 현재 주소 notifier
  ValueNotifier<String> get currentAddressNotifier => _currentAddress;

  /// 현재 맵 컨트롤러
  NaverMapController? get mapController => _mapController;

  /// 현재 위치
  NLatLng get currentPosition => _currentPosition.value;

  /// 네이버 맵 초기화 (이제 main.dart에서 처리됨)
  static Future<void> initialize() async {
    // main.dart에서 FlutterNaverMap().init()으로 초기화되므로 별도 처리 불필요
    AppLogger.info('네이버 맵은 이미 main.dart에서 초기화됨');
  }

  /// 맵 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    _isMapReady.value = true;
    AppLogger.info('네이버 맵 컨트롤러 설정 완료');

    // 맵이 준비되면 자동으로 현재 위치 가져오기
    getCurrentLocation();
  }

  /// 특정 위치로 이동
  Future<void> moveToPosition(NLatLng position, {double zoom = 14}) async {
    if (_mapController == null) {
      AppLogger.warning('맵 컨트롤러가 준비되지 않음');
      return;
    }

    try {
      // 애니메이션과 함께 카메라 이동
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: position,
        zoom: zoom,
      )..setAnimation(animation: NCameraAnimation.easing, duration: const Duration(milliseconds: 1000));

      await _mapController!.updateCamera(cameraUpdate);
      _currentPosition.value = position;
      AppLogger.info('맵 위치 이동 완료: ${position.latitude}, ${position.longitude}, zoom: $zoom');
    } catch (e) {
      AppLogger.error('맵 위치 이동 실패', error: e);
    }
  }

  /// 서울시청으로 이동
  Future<void> moveToSeoulCityHall() async {
    const seoulCityHall = NLatLng(37.5666805, 126.9784147);
    await moveToPosition(seoulCityHall);
    _currentAddress.value = '서울특별시 중구 세종대로 110';
  }

  /// 강남역으로 이동
  Future<void> moveToGangnam() async {
    const gangnam = NLatLng(37.4979517, 127.0276188);
    await moveToPosition(gangnam);
    _currentAddress.value = '서울특별시 강남구 강남대로 지하 396';
  }

  /// 홍대입구역으로 이동
  Future<void> moveToHongdae() async {
    const hongdae = NLatLng(37.5563528, 126.9236437);
    await moveToPosition(hongdae);
    _currentAddress.value = '서울특별시 마포구 양화로 지하 188';
  }

  /// 줌 레벨 변경
  Future<void> setZoom(double zoom) async {
    if (_mapController == null) return;

    try {
      final cameraUpdate = NCameraUpdate.withParams(zoom: zoom);
      await _mapController!.updateCamera(cameraUpdate);
      AppLogger.info('맵 줌 레벨 변경: $zoom');
    } catch (e) {
      AppLogger.error('맵 줌 변경 실패', error: e);
    }
  }

  /// 줌 인
  Future<void> zoomIn() async {
    if (_mapController == null) return;
    await _mapController!.updateCamera(NCameraUpdate.zoomIn());
  }

  /// 줌 아웃
  Future<void> zoomOut() async {
    if (_mapController == null) return;
    await _mapController!.updateCamera(NCameraUpdate.zoomOut());
  }

  /// 마커 추가
  Future<void> addMarker(NLatLng position, String title) async {
    if (_mapController == null) return;

    try {
      final marker = NMarker(
        id: 'marker_${DateTime.now().millisecondsSinceEpoch}',
        position: position,
      );

      final infoWindow = NInfoWindow.onMap(
        id: 'info_${DateTime.now().millisecondsSinceEpoch}',
        text: title,
        position: position,
      );

      await _mapController!.addOverlay(marker);
      await _mapController!.addOverlay(infoWindow);

      AppLogger.info(
        '마커 추가: $title at ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      AppLogger.error('마커 추가 실패', error: e);
    }
  }

  /// 모든 마커 제거
  Future<void> clearMarkers() async {
    if (_mapController == null) return;

    try {
      await _mapController!.clearOverlays();
      AppLogger.info('모든 마커 제거');
    } catch (e) {
      AppLogger.error('마커 제거 실패', error: e);
    }
  }

  /// 현재 위치 가져오기
  Future<void> getCurrentLocation({bool moveMap = true}) async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = NLatLng(position.latitude, position.longitude);

      // 위치가 실제로 변경된 경우에만 업데이트
      if (_currentPosition.value.latitude != position.latitude ||
          _currentPosition.value.longitude != position.longitude) {
        _currentPosition.value = currentLatLng;

        // 주소 변환
        await _updateAddressFromPosition(currentLatLng);

        // 맵이 준비되었다면 현재 위치로 이동 (선택적)
        if (_mapController != null && moveMap) {
          await moveToPosition(currentLatLng, zoom: 16); // 더 높은 줌 레벨로 설정
          await addCurrentLocationMarker();
        } else if (_mapController != null) {
          // 맵을 이동하지 않더라도 마커는 업데이트
          await addCurrentLocationMarker();
        }

        AppLogger.info(
          '현재 위치 업데이트: ${position.latitude}, ${position.longitude}',
        );
      } else {
        AppLogger.info('위치 변경 없음: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      AppLogger.error('현재 위치 가져오기 실패', error: e);
      _currentAddress.value = '위치를 가져올 수 없습니다: ${e.toString()}';
    }
  }

  /// 현재 위치 마커 추가
  Future<void> addCurrentLocationMarker() async {
    if (_mapController == null) return;

    try {
      // 기존 마커 제거
      await clearMarkers();

      // 현재 위치 마커 추가
      final marker = NMarker(
        id: 'current_location',
        position: _currentPosition.value,
      );

      await _mapController!.addOverlay(marker);
      AppLogger.info('현재 위치 마커 추가');
    } catch (e) {
      AppLogger.error('현재 위치 마커 추가 실패', error: e);
      // 기본 마커로 fallback
      await addMarker(_currentPosition.value, '현재 위치');
    }
  }

  /// 위치에서 주소 변환
  Future<void> _updateAddressFromPosition(NLatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = '';

        if (place.administrativeArea != null) {
          address += place.administrativeArea!;
        }
        if (place.locality != null) {
          address += ' ${place.locality!}';
        }
        if (place.thoroughfare != null) {
          address += ' ${place.thoroughfare!}';
        }
        if (place.subThoroughfare != null) {
          address += ' ${place.subThoroughfare!}';
        }

        _currentAddress.value = address.trim().isNotEmpty
            ? address.trim()
            : '주소를 찾을 수 없습니다';
      } else {
        _currentAddress.value = '주소를 찾을 수 없습니다';
      }
    } catch (e) {
      AppLogger.error('주소 변환 실패', error: e);
      _currentAddress.value = '주소 변환 실패';
    }
  }

  /// 메모리 해제
  void dispose() {
    _isMapReady.dispose();
    _currentPosition.dispose();
    _currentAddress.dispose();
    _mapController = null;
  }
}
