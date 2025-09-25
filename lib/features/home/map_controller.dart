import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/services/logging/app_logger.dart';
import 'models/pothole_marker.dart';

/// 네이버 맵 관련 비즈니스 로직을 담당하는 컨트롤러
class MapController {
  NaverMapController? _mapController;
  final ValueNotifier<bool> _isMapReady = ValueNotifier<bool>(false);
  final ValueNotifier<NLatLng> _currentPosition = ValueNotifier<NLatLng>(
    const NLatLng(37.5665, 126.9780), // 서울시청 기본 위치 (JSON 데이터와 맞춤)
  );
  final ValueNotifier<String> _currentAddress = ValueNotifier<String>(
    '위치 로딩 중...',
  );

  final Map<String, NOverlayImage> _markerIconCache = {};
  NOverlayImage? _currentLocationOverlayImage;

  // 포트홀 마커 관리
  final List<PotholeMarker> _potholeMarkers = [];
  final Map<String, NMarker> _activeMarkers = {};

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
  void setMapController(
    NaverMapController controller,
    BuildContext context,
  ) {
    _mapController = controller;
    _isMapReady.value = true;
    AppLogger.info('네이버 맵 컨트롤러 설정 완료');

    // 맵이 준비되면 자동으로 현재 위치 가져오기
    getCurrentLocation(context: context, moveMap: true);

    // 기존에 저장해 둔 포트홀 마커가 있다면 맵에 렌더링
    _renderStoredPotholeMarkers();
  }

  /// 특정 위치로 이동
  Future<void> moveToPosition(NLatLng position, {double zoom = 18}) async {
    if (_mapController == null) {
      AppLogger.warning('맵 컨트롤러가 준비되지 않음');
      return;
    }

    try {
      // 애니메이션과 함께 카메라 이동
      final cameraUpdate =
          NCameraUpdate.scrollAndZoomTo(target: position, zoom: zoom)
            ..setAnimation(
              animation: NCameraAnimation.easing,
              duration: const Duration(milliseconds: 1000),
            );

      await _mapController!.updateCamera(cameraUpdate);
      _currentPosition.value = position;
      AppLogger.info(
        '맵 위치 이동 완료: ${position.latitude}, ${position.longitude}, zoom: $zoom',
      );
    } catch (e) {
      AppLogger.error('맵 위치 이동 실패', error: e);
    }
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

  /// 현재 위치로 이동 (버튼 전용)
  Future<void> moveToCurrentLocation(BuildContext context) async {
    try {
      // 현재 저장된 위치로 먼저 이동
      if (_mapController != null) {
        await moveToPosition(_currentPosition.value, zoom: 15);
        await addCurrentLocationMarker(context);
        AppLogger.info('저장된 현재 위치로 이동 완료');
      }

      // 그 다음 실제 현재 위치를 다시 가져와서 업데이트
      await getCurrentLocation(moveMap: true, context: context);
    } catch (e) {
      AppLogger.error('현재 위치로 이동 실패', error: e);
    }
  }

  /// 현재 위치 가져오기
  Future<void> getCurrentLocation({
    required BuildContext context,
    bool moveMap = true,
  }) async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.info('위치 권한 요청 중...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.error('위치 권한이 거부됨');
          _currentAddress.value = '위치 권한이 필요합니다';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error('위치 권한이 영구적으로 거부됨');
        _currentAddress.value = '설정에서 위치 권한을 허용해주세요';
        return;
      }

      AppLogger.info('위치 서비스 사용 가능 여부 확인 중...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.error('위치 서비스가 비활성화됨');
        _currentAddress.value = '위치 서비스를 활성화해주세요';
        return;
      }

      AppLogger.info('현재 위치 가져오는 중...');

      // 현재 위치 가져오기 (타임아웃과 함께)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () async {
          AppLogger.warning('위치 가져오기 타임아웃, 마지막 알려진 위치 사용');
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            return lastPosition;
          }
          throw Exception('위치 정보를 가져올 수 없습니다');
        },
      );

      final currentLatLng = NLatLng(position.latitude, position.longitude);
      AppLogger.info('위치 가져오기 성공: ${position.latitude}, ${position.longitude}');

      // 위치 업데이트
      _currentPosition.value = currentLatLng;

      // 주소 변환
      await _updateAddressFromPosition(currentLatLng);

      // 맵이 준비되었다면 현재 위치로 이동 (선택적)
      if (_mapController != null && moveMap) {
        await moveToPosition(
          currentLatLng,
          zoom: 15,
        ); // 100m 기준 줌 레벨로 설정 (15가 약 100m)
        await addCurrentLocationMarker(context);
      } else if (_mapController != null) {
        // 맵을 이동하지 않더라도 마커는 업데이트
        await addCurrentLocationMarker(context);
      }

      AppLogger.info('현재 위치 업데이트 완료');
    } catch (e) {
      AppLogger.error('현재 위치 가져오기 실패', error: e);

      // 기본 서울 시청 위치로 설정
      final defaultPosition = const NLatLng(37.5665, 126.9780);
      _currentPosition.value = defaultPosition;
      _currentAddress.value = '서울특별시 중구 세종대로 110 (기본 위치)';

      AppLogger.info('기본 위치로 설정됨');

      // 맵이 준비되었다면 기본 위치로 이동
      if (_mapController != null && moveMap) {
        await moveToPosition(defaultPosition, zoom: 15);
        await addCurrentLocationMarker(context);
      }
    }
  }

  /// 현재 위치 마커 추가 (포트홀 마커는 유지)
  Future<void> addCurrentLocationMarker(BuildContext context) async {
    if (_mapController == null) return;

    try {
      // 현재 위치 마커 추가 (파란색 원형 마커)
      final marker = NMarker(
        id: 'current_location',
        position: _currentPosition.value,
        size: const NSize(56, 56),
        anchor: const NPoint(0.5, 0.5),
        icon: await _buildCurrentLocationOverlay(context),
      );

      await _mapController!.addOverlay(marker);
      AppLogger.info('현재 위치 마커 추가');
    } catch (e) {
      AppLogger.error('현재 위치 마커 추가 실패', error: e);
      // 기본 마커로 fallback
      await addMarker(_currentPosition.value, '현재 위치');
    }
  }

  Future<NOverlayImage> _buildCurrentLocationOverlay(BuildContext context) async {
    if (_currentLocationOverlayImage != null) {
      return _currentLocationOverlayImage!;
    }

    final overlay = await NOverlayImage.fromWidget(
      context: context,
      size: const Size(56, 56),
      widget: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33007AFF),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    _currentLocationOverlayImage = overlay;
    return overlay;
  }

  /// 위치에서 주소 변환
  Future<void> _updateAddressFromPosition(NLatLng position) async {
    try {
      AppLogger.info('주소 변환 시작: ${position.latitude}, ${position.longitude}');

      // 좌표 기반 지역 정보 (geocoding이 실패할 때 대비)
      String regionAddress = _getRegionFromCoordinates(position);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          AppLogger.info('Placemark 정보: ${place.toString()}');

          String address = '';

          // 한국 주소 형식으로 조합
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            address += place.administrativeArea!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            if (address.isNotEmpty) address += ' ';
            address += place.locality!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (address.isNotEmpty) address += ' ';
            address += place.subLocality!;
          }
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            if (address.isNotEmpty) address += ' ';
            address += place.thoroughfare!;
          }
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            if (address.isNotEmpty) address += ' ';
            address += place.subThoroughfare!;
          }

          final finalAddress = address.trim();
          _currentAddress.value = finalAddress.isNotEmpty
              ? finalAddress
              : regionAddress;

          AppLogger.info('최종 주소: ${_currentAddress.value}');
        } else {
          _currentAddress.value = regionAddress;
          AppLogger.warning('Placemark 정보 없음, 지역 정보 표시');
        }
      } catch (geocodingError) {
        AppLogger.warning('Geocoding 서비스 오류: $geocodingError');
        _currentAddress.value = regionAddress;
      }
    } catch (e) {
      AppLogger.error('주소 변환 완전 실패', error: e);
      _currentAddress.value = _getRegionFromCoordinates(position);
    }
  }

  /// 좌표에서 대략적인 지역 정보 추출
  String _getRegionFromCoordinates(NLatLng position) {
    final lat = position.latitude;
    final lng = position.longitude;

    // 한국 주요 지역 좌표 범위로 대략적인 주소 추정
    if (lat >= 37.4 && lat <= 37.7 && lng >= 126.8 && lng <= 127.2) {
      return '서울특별시';
    } else if (lat >= 37.2 && lat <= 37.5 && lng >= 126.6 && lng <= 127.0) {
      return '경기도 수원시 일대';
    } else if (lat >= 35.1 && lat <= 35.3 && lng >= 129.0 && lng <= 129.2) {
      return '부산광역시';
    } else if (lat >= 35.8 && lat <= 36.0 && lng >= 128.5 && lng <= 128.7) {
      return '대구광역시';
    } else if (lat >= 37.2 && lat <= 37.4 && lng >= 127.3 && lng <= 127.5) {
      return '경기도 용인시 일대';
    } else if (lat >= 33.2 && lat <= 33.6 && lng >= 126.4 && lng <= 126.9) {
      return '제주특별자치도 제주시';
    } else if (lat >= 33.1 && lat <= 33.3 && lng >= 126.3 && lng <= 126.7) {
      return '제주특별자치도 서귀포시';
    } else if (lat >= 36.3 && lat <= 36.4 && lng >= 127.3 && lng <= 127.5) {
      return '대전광역시';
    } else if (lat >= 35.1 && lat <= 35.3 && lng >= 126.8 && lng <= 127.0) {
      return '광주광역시';
    } else if (lat >= 35.5 && lat <= 35.7 && lng >= 129.3 && lng <= 129.4) {
      return '울산광역시';
    } else if (lat >= 36.5 && lat <= 36.6 && lng >= 126.6 && lng <= 126.8) {
      return '충청남도 천안시 일대';
    } else if (lat >= 33.0 && lat <= 38.6 && lng >= 124.6 && lng <= 131.9) {
      return '대한민국';
    } else {
      return '위도: ${lat.toStringAsFixed(4)}, 경도: ${lng.toStringAsFixed(4)}';
    }
  }

  /// 포트홀 마커 추가
  Future<void> addPotholeMarkers(List<PotholeMarker> markers) async {
    if (markers.isEmpty) {
      AppLogger.info('추가할 포트홀 마커가 없음');
      return;
    }

    AppLogger.info('포트홀 마커 저장: ${markers.length}개');

    _potholeMarkers
      ..clear()
      ..addAll(markers);

    if (_mapController == null) {
      AppLogger.info('맵 컨트롤러 준비 전, 마커만 저장함');
      return;
    }

    await _renderStoredPotholeMarkers();
  }

  Future<void> _renderStoredPotholeMarkers() async {
    if (_mapController == null) {
      AppLogger.warning('맵 컨트롤러가 없어 저장된 마커 렌더링 불가');
      return;
    }

    if (_potholeMarkers.isEmpty) {
      AppLogger.info('렌더링할 포트홀 마커가 없음');
      return;
    }

    try {
      AppLogger.info('포트홀 마커 렌더링 시작: ${_potholeMarkers.length}개');

      // 기존 포트홀 마커 제거
      await _clearPotholeMarkers();

      // 새 마커를 배치로 나누어 추가 (한 번에 너무 많이 추가하면 크래시 방지)
      int successCount = 0;
      final batchSize = 10; // 한 번에 10개씩 추가

      for (int i = 0; i < _potholeMarkers.length; i += batchSize) {
        final endIndex =
            (i + batchSize < _potholeMarkers.length) ? i + batchSize : _potholeMarkers.length;
        final batch = _potholeMarkers.sublist(i, endIndex);

        AppLogger.info('마커 배치 ${i ~/ batchSize + 1} 추가 중: ${batch.length}개');

        for (final marker in batch) {
          try {
            await _addSinglePotholeMarker(marker);
            successCount++;
          } catch (e) {
            AppLogger.error('개별 포트홀 마커 추가 실패: ${marker.id}', error: e);
          }
        }

        // 배치 간 잠깐 대기 (메모리 정리 시간 확보)
        if (i + batchSize < _potholeMarkers.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      AppLogger.info('포트홀 마커 렌더링 완료: $successCount/${_potholeMarkers.length}개 성공');
    } catch (e) {
      AppLogger.error('포트홀 마커 렌더링 실패', error: e);
    }
  }

  /// 단일 포트홀 마커 추가
  Future<void> _addSinglePotholeMarker(
    PotholeMarker marker, {
    BuildContext? context,
  }) async {
    if (_mapController == null) {
      AppLogger.warning('맵 컨트롤러가 null이어서 마커 추가 불가: ${marker.id}');
      return;
    }

    try {
      // 위치 검증
      if (marker.position.latitude.abs() > 90 || marker.position.longitude.abs() > 180) {
        AppLogger.error('잘못된 위치 좌표: ${marker.id} - ${marker.position.latitude}, ${marker.position.longitude}');
        return;
      }

      NOverlayImage? icon;
      if (marker.type == PotholeMarkerType.individual) {
        try {
          icon = await _getMarkerIcon(marker.status);
        } catch (e, stackTrace) {
          AppLogger.warning(
            '커스텀 마커 아이콘 로드 실패: ${marker.id}, status: ${marker.status}',
            error: e,
            stackTrace: stackTrace,
          );
          icon = null;
        }
      }

      final hasCustomIcon = icon != null;

      final nMarker = NMarker(
        id: marker.id,
        position: marker.position,
        size: hasCustomIcon ? const NSize(40, 40) : NMarker.autoSize,
        anchor: hasCustomIcon
            ? const NPoint(0.5, 1.0)
            : NMarker.defaultAnchor, // 기본 마커는 기본 앵커 사용
        icon: icon,
      );

      if (marker.type == PotholeMarkerType.cluster || !hasCustomIcon) {
        Color markerColor;
        switch (marker.riskLevel) {
          case PotholeRiskLevel.high:
            markerColor = Colors.red;
            break;
          case PotholeRiskLevel.medium:
            markerColor = Colors.orange;
            break;
          case PotholeRiskLevel.low:
            markerColor = Colors.yellow;
            break;
        }

        nMarker.setIconTintColor(markerColor);
      }
      AppLogger.info('기본 색상 마커 설정: ${marker.id}, 색상: ${marker.riskLevel}');

      // 마커 클릭 이벤트 설정
      nMarker.setOnTapListener((overlay) {
        try {
          _onPotholeMarkerTapped(marker);
        } catch (e) {
          AppLogger.error('마커 클릭 처리 실패: ${marker.id}', error: e);
        }
      });

      // 맵에 마커 추가
      await _mapController!.addOverlay(nMarker);
      _activeMarkers[marker.id] = nMarker;

      AppLogger.info('포트홀 마커 추가 성공: ${marker.id}');
    } catch (e) {
      AppLogger.error('포트홀 마커 추가 실패: ${marker.id}', error: e);
      // 재시도 또는 기본 마커로 대체하지 않음 (로그만 남김)
    }
  }

  Future<NOverlayImage> _getMarkerIcon(String status) async {
    final key = status.toLowerCase();
    final cached = _markerIconCache[key];
    if (cached != null) {
      return cached;
    }

    final assetPath = _mapStatusToAsset(key);
    final overlay = NOverlayImage.fromAssetImage(assetPath);

    _markerIconCache[key] = overlay;
    return overlay;
  }

  String _mapStatusToAsset(String status) {
    switch (status) {
      case 'small':
        return 'assets/images/general.png';
      case 'medium':
      case 'meduim':
        return 'assets/images/waring.png';
      case 'high':
        return 'assets/images/danger.png';
      default:
        return 'assets/images/general.png';
    }
  }

  /// 포트홀 마커 클릭 처리
  void _onPotholeMarkerTapped(PotholeMarker marker) {
    AppLogger.info('포트홀 마커 클릭: ${marker.id}');
    // TODO: 포트홀 상세 정보 표시 또는 bottom sheet 표시
  }

  /// 포트홀 마커 제거
  Future<void> _clearPotholeMarkers() async {
    if (_mapController == null) return;

    try {
      for (final markerId in _activeMarkers.keys.toList()) {
        final marker = _activeMarkers[markerId];
        if (marker != null) {
          await _mapController!.deleteOverlay(marker.info);
          _activeMarkers.remove(markerId);
        }
      }
      AppLogger.info('모든 포트홀 마커 제거');
    } catch (e) {
      AppLogger.error('포트홀 마커 제거 실패', error: e);
    }
  }

  /// 줌 레벨에 따른 마커 표시 방식 변경
  Future<void> updateMarkersForZoomLevel(double zoomLevel) async {
    if (_mapController == null) return;

    try {
      // 포트홀 마커가 없으면 업데이트하지 않음
      if (_potholeMarkers.isEmpty) {
        AppLogger.info('포트홀 마커가 없어서 줌 레벨 업데이트 건너뜀');
        return;
      }

      AppLogger.info('줌 레벨 $zoomLevel, 전체 마커 수: ${_potholeMarkers.length}');

      // 모든 마커를 항상 표시하도록 변경 (줌 레벨에 관계없이)
      // 줌 레벨이 높으면(확대) 개별 마커를 우선하고, 낮으면(축소) 클러스터도 함께 표시
      List<PotholeMarker> markersToShow = [];

      if (zoomLevel >= 13.0) {
        // 줌 인 상태: 모든 개별 마커 표시
        markersToShow = _potholeMarkers
            .where((m) => m.type == PotholeMarkerType.individual)
            .toList();
        AppLogger.info('개별 마커 표시: ${markersToShow.length}개');
      } else {
        // 줌 아웃 상태: 클러스터 마커와 개별 마커 모두 표시
        markersToShow = _potholeMarkers.toList();
        AppLogger.info('모든 마커 표시: ${markersToShow.length}개');
      }

      if (markersToShow.isNotEmpty) {
        await addPotholeMarkers(markersToShow);
      }

      AppLogger.info('줌 레벨 $zoomLevel에 따른 마커 업데이트 완료');
    } catch (e) {
      AppLogger.error('줌 레벨별 마커 업데이트 실패', error: e);
    }
  }

  /// JSON 파일에서 포트홀 데이터 로드
  Future<List<PotholeMarker>> loadPotholeMarkersFromJson() async {
    final List<PotholeMarker> allMarkers = [];

    try {
      // 1. pothole_data.json 파일 로드 시도
      try {
        AppLogger.info('JSON 파일 로딩 시도: assets/data/pothole_data.json');
        final response1 = await rootBundle.loadString('assets/data/pothole_data.json');
        AppLogger.info('pothole_data.json 로딩 성공, 길이: ${response1.length}');

        final data1 = json.decode(response1);
        if (data1 is List) {
          AppLogger.info('pothole_data.json: 배열 형태의 포트홀 데이터 ${data1.length}개 발견');
          for (int i = 0; i < data1.length; i++) {
            try {
              final potholeData = data1[i];
              final pothole = PotholeData(
                id: potholeData['id']?.toString() ?? 'pothole_data_$i',
                latitude: (potholeData['latitude'] ?? 0.0).toDouble(),
                longitude: (potholeData['langitude'] ?? potholeData['longitude'] ?? 0.0).toDouble(),
                riskLevel: PotholeRiskLevel.high,
                description: potholeData['description'] ?? '',
                reportedAt: DateTime.tryParse(potholeData['createdAt'] ?? '') ?? DateTime.now(),
                status: (potholeData['status'] ?? potholeData['size'] ?? 'high')
                    .toString()
                    .toLowerCase(),
              );
              allMarkers.add(PotholeMarker.individual(pothole));
              AppLogger.info('pothole_data.json에서 포트홀 ${pothole.id} 파싱 완료');
            } catch (e) {
              AppLogger.error('pothole_data.json 포트홀 데이터 파싱 실패: ${data1[i]}', error: e);
            }
          }
        }
      } catch (e) {
        AppLogger.warning('pothole_data.json 로딩 실패: $e');
      }

      // 2. potholes.json 파일 로드 시도
      try {
        AppLogger.info('JSON 파일 로딩 시도: assets/data/potholes.json');
        final response2 = await rootBundle.loadString('assets/data/potholes.json');
        AppLogger.info('potholes.json 로딩 성공, 길이: ${response2.length}');

        final data2 = json.decode(response2);
        if (data2 is Map<String, dynamic>) {
          AppLogger.info('potholes.json: 객체 형태의 JSON 데이터, 키들: ${data2.keys.toList()}');

          // 개별 포트홀 데이터 파싱
          if (data2['potholes'] != null) {
            final List<dynamic> potholes = data2['potholes'];
            AppLogger.info('potholes.json: 포트홀 데이터 ${potholes.length}개 발견');

            for (final potholeJson in potholes) {
              try {
                final pothole = _parsePotholeFromJson(potholeJson);
                allMarkers.add(PotholeMarker.individual(pothole));
                AppLogger.info('potholes.json에서 포트홀 ${pothole.id} 파싱 완료');
              } catch (e) {
                AppLogger.error('potholes.json 포트홀 데이터 파싱 실패: $potholeJson', error: e);
              }
            }
          }

          // 클러스터 데이터 파싱
          if (data2['clusters'] != null) {
            final List<dynamic> clusters = data2['clusters'];
            AppLogger.info('potholes.json: 클러스터 데이터 ${clusters.length}개 발견');

            for (final clusterJson in clusters) {
              try {
                final cluster = _parseClusterFromJson(clusterJson);
                allMarkers.add(PotholeMarker.cluster(cluster));
                AppLogger.info('potholes.json에서 클러스터 ${cluster.id} 파싱 완료');
              } catch (e) {
                AppLogger.error('potholes.json 클러스터 데이터 파싱 실패: $clusterJson', error: e);
              }
            }
          }
        }
      } catch (e) {
        AppLogger.warning('potholes.json 로딩 실패: $e');
      }

      AppLogger.info('모든 JSON 파일에서 총 포트홀 마커 ${allMarkers.length}개 로드 완료');

      // 마커가 하나도 없으면 샘플 데이터 사용
      if (allMarkers.isEmpty) {
        AppLogger.info('로드된 마커가 없어 샘플 데이터 사용');
        return generateSamplePotholeMarkers();
      }

      return allMarkers;
    } catch (e) {
      AppLogger.error('JSON 파일에서 포트홀 데이터 로드 실패', error: e);
      // 오류 시 샘플 데이터 반환
      AppLogger.info('오류로 인해 샘플 데이터 사용');
      return generateSamplePotholeMarkers();
    }
  }

  /// JSON에서 포트홀 데이터 파싱
  PotholeData _parsePotholeFromJson(Map<String, dynamic> json) {
    return PotholeData(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      riskLevel: _parseRiskLevel(json['riskLevel']),
      description: json['description'] ?? '',
      reportedAt: DateTime.tryParse(json['reportedAt'] ?? '') ?? DateTime.now(),
      status: (json['status'] ?? json['size'] ?? json['riskLevel'] ?? 'medium')
          .toString()
          .toLowerCase(),
    );
  }

  /// JSON에서 클러스터 데이터 파싱
  PotholeCluster _parseClusterFromJson(Map<String, dynamic> json) {
    return PotholeCluster(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      count: json['count'] ?? 1,
      potholes: [], // 실제 구현시에는 potholeIds를 기반으로 포트홀 데이터 매칭
    );
  }

  /// 위험도 문자열을 enum으로 변환
  PotholeRiskLevel _parseRiskLevel(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'high':
        return PotholeRiskLevel.high;
      case 'medium':
        return PotholeRiskLevel.medium;
      case 'low':
      default:
        return PotholeRiskLevel.low;
    }
  }

  /// 샘플 포트홀 데이터 생성 (테스트용 - fallback)
  List<PotholeMarker> generateSamplePotholeMarkers() {
    final currentPos = _currentPosition.value;

    final sampleData = [
      // 개별 포트홀 마커들
      PotholeMarker.individual(
        PotholeData(
          id: 'p1',
          latitude: currentPos.latitude + 0.001,
          longitude: currentPos.longitude + 0.001,
          riskLevel: PotholeRiskLevel.high,
          description: '큰 포트홀',
          reportedAt: DateTime.now(),
          status: 'high',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'p2',
          latitude: currentPos.latitude - 0.001,
          longitude: currentPos.longitude + 0.0005,
          riskLevel: PotholeRiskLevel.medium,
          description: '중간 포트홀',
          reportedAt: DateTime.now(),
          status: 'medium',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'p3',
          latitude: currentPos.latitude + 0.0005,
          longitude: currentPos.longitude - 0.001,
          riskLevel: PotholeRiskLevel.low,
          description: '작은 포트홀',
          reportedAt: DateTime.now(),
          status: 'small',
        ),
      ),

      // 클러스터 마커들
      PotholeMarker.cluster(
        PotholeCluster(
          id: 'c1',
          latitude: currentPos.latitude - 0.002,
          longitude: currentPos.longitude - 0.002,
          count: 5,
          potholes: [], // 실제로는 포트홀 데이터 리스트
        ),
      ),
      PotholeMarker.cluster(
        PotholeCluster(
          id: 'c2',
          latitude: currentPos.latitude + 0.002,
          longitude: currentPos.longitude + 0.002,
          count: 12,
          potholes: [], // 실제로는 포트홀 데이터 리스트
        ),
      ),
    ];

    return sampleData;
  }

  /// 메모리 해제
  void dispose() {
    _isMapReady.dispose();
    _currentPosition.dispose();
    _currentAddress.dispose();
    _potholeMarkers.clear();
    _activeMarkers.clear();
    _markerIconCache.clear();
    _currentLocationOverlayImage = null;
    _mapController = null;
  }
}
