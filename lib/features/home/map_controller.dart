import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:porthole_in_jeju/core/models/pothole_status.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/pothole.dart';
import '../../core/services/api/pothole_api_service.dart';
import '../../core/services/logging/app_logger.dart';
import '../pothole_detail/models/pothole_info.dart';
import '../pothole_detail/widgets/pothole_detail_bottom_sheet.dart';
import 'models/pothole_marker.dart';

/// 네이버 맵 관련 비즈니스 로직을 담당하는 컨트롤러 (Singleton)
class MapController {
  // Singleton 인스턴스
  static final MapController _instance = MapController._internal();

  // Factory 생성자로 항상 같은 인스턴스 반환
  factory MapController() => _instance;

  // Private 생성자
  MapController._internal();

  static const double _defaultSearchDistance = 100000000;
  static const List<String> _fallbackDetailImages = [
    'assets/images/danger.png',
    'assets/images/general.png',
    'assets/images/waring.png',
  ];

  NaverMapController? _mapController;
  final ValueNotifier<bool> _isMapReady = ValueNotifier<bool>(false);
  final ValueNotifier<NLatLng> _currentPosition = ValueNotifier<NLatLng>(
    const NLatLng(37.5665, 126.9780), // 서울시청 기본 위치 (JSON 데이터와 맞춤)
  );
  final ValueNotifier<String> _currentAddress = ValueNotifier<String>(
    '위치 로딩 중...',
  );

  final Map<String, NOverlayImage> _markerIconCache = {};
  final Map<String, NOverlayImage> _clusterIconCache = {};
  NOverlayImage? _currentLocationOverlayImage;

  // 포트홀 마커 관리
  final List<PotholeMarker> _potholeMarkers = [];
  final Map<String, NClusterableMarker> _activeMarkers = {};

  // BuildContext 참조 (bottom sheet 표시용)
  BuildContext? _buildContext;

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
  void setMapController(NaverMapController controller, BuildContext context) {
    _mapController = controller;
    _isMapReady.value = true;
    _buildContext = context;
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
      // 컨텍스트가 필요한 오버레이를 먼저 빌드
      await _buildCurrentLocationOverlay(context);

      // 현재 저장된 위치로 먼저 이동
      if (_mapController != null) {
        await moveToPosition(_currentPosition.value, zoom: 15);
        // ignore: use_build_context_synchronously
        await addCurrentLocationMarker(context);
        AppLogger.info('저장된 현재 위치로 이동 완료');
      }

      // 그 다음 실제 현재 위치를 다시 가져와서 업데이트
      // ignore: use_build_context_synchronously
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
      Position position =
          await Geolocator.getCurrentPosition(
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
        // ignore: use_build_context_synchronously
        await addCurrentLocationMarker(context);
      } else if (_mapController != null) {
        // 맵을 이동하지 않더라도 마커는 업데이트
        // ignore: use_build_context_synchronously
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
        // ignore: use_build_context_synchronously
        await addCurrentLocationMarker(context);
      }
    }
  }

  /// 현재 위치 마커 추가 (포트홀 마커는 유지)
  Future<void> addCurrentLocationMarker(BuildContext context) async {
    if (_mapController == null) return;

    // 캐시된 오버레이가 없으면 빌드, 있으면 캐시된 것 사용
    if (_currentLocationOverlayImage == null) {
      await _buildCurrentLocationOverlay(context);
    }

    try {
      // 현재 위치 마커 추가 (파란색 원형 마커)
      final marker = NMarker(
        id: 'current_location',
        position: _currentPosition.value,
        size: const NSize(48, 56),
        anchor: const NPoint(0.5, 0.5),
        icon: _currentLocationOverlayImage!,
      );

      await _mapController!.addOverlay(marker);
      AppLogger.info('현재 위치 마커 추가');
    } catch (e) {
      AppLogger.error('현재 위치 마커 추가 실패', error: e);
      // 기본 마커로 fallback
      await addMarker(_currentPosition.value, '현재 위치');
    }
  }

  Future<NOverlayImage> _buildCurrentLocationOverlay(
    BuildContext context,
  ) async {
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
                border: Border.all(color: Colors.white, width: 2),
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
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
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
          if (place.subThoroughfare != null &&
              place.subThoroughfare!.isNotEmpty) {
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
  Future<void> addPotholeMarkers(
    List<PotholeMarker> markers, {
    BuildContext? context,
  }) async {
    if (markers.isEmpty) {
      AppLogger.info('추가할 포트홀 마커가 없음');
      return;
    }

    // BuildContext 저장
    if (context != null) {
      _buildContext = context;
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

    final context = _buildContext;

    try {
      AppLogger.info('포트홀 마커 렌더링 시작: ${_potholeMarkers.length}개');

      await _clearPotholeMarkers();

      final clusterableMarkers = <NClusterableMarker>{};

      for (final marker in _potholeMarkers) {
        final clusterable = await _buildClusterableMarker(
          marker,
          // ignore: use_build_context_synchronously
          context: context,
        );
        if (clusterable != null) {
          clusterableMarkers.add(clusterable);
        }
      }

      if (clusterableMarkers.isEmpty) {
        AppLogger.warning('생성된 포트홀 마커가 없어 렌더링을 건너뜁니다');
        return;
      }

      await _mapController!.addOverlayAll(clusterableMarkers);
      for (final marker in clusterableMarkers) {
        _activeMarkers[marker.info.id] = marker;
      }

      AppLogger.info('포트홀 마커 렌더링 완료: ${clusterableMarkers.length}개');
    } catch (e, stackTrace) {
      AppLogger.error('포트홀 마커 렌더링 실패', error: e, stackTrace: stackTrace);
    }
  }

  Future<NClusterableMarker?> _buildClusterableMarker(
    PotholeMarker marker, {
    BuildContext? context,
  }) async {
    if (_mapController == null) {
      AppLogger.warning('맵 컨트롤러가 null이어서 마커 생성 불가: ${marker.id}');
      return null;
    }

    if (marker.type != PotholeMarkerType.individual ||
        marker.potholeData == null) {
      AppLogger.warning('클러스터링 가능한 마커는 개별 포트홀 데이터가 필요합니다: ${marker.id}');
      return null;
    }

    try {
      // 위치 검증
      if (marker.position.latitude.abs() > 90 ||
          marker.position.longitude.abs() > 180) {
        AppLogger.error(
          '잘못된 위치 좌표: ${marker.id} - ${marker.position.latitude}, ${marker.position.longitude}',
        );
        return null;
      }

      final icon = await _getMarkerIcon(marker.status);
      final clusterableMarker = NClusterableMarker(
        id: marker.id,
        position: marker.position,
        icon: icon,
        size: const NSize(32, 40),
        anchor: const NPoint(0.5, 1.0),
        tags: {
          'riskLevel': marker.riskLevel.name,
          'potholeId': marker.potholeData!.id,
        },
        isForceShowIcon: true,
      );

      clusterableMarker.setOnTapListener((overlay) {
        try {
          _onPotholeMarkerTapped(marker);
        } catch (e, stackTrace) {
          AppLogger.error(
            '클러스터블 마커 탭 처리 실패: ${marker.id}',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });

      return clusterableMarker;
    } catch (e, stackTrace) {
      AppLogger.error(
        '클러스터링 가능한 마커 생성 실패: ${marker.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<NOverlayImage> _getMarkerIcon(PotholeStatus status) async {
    final key = status.name.toLowerCase();
    final cached = _markerIconCache[key];
    if (cached != null) {
      return cached;
    }

    final assetPath = _mapStatusToAsset(status);
    final overlay = NOverlayImage.fromAssetImage(assetPath);

    _markerIconCache[key] = overlay;
    return overlay;
  }

  Future<NOverlayImage> _getClusterMarkerIcon({
    required String label,
    required PotholeRiskLevel riskLevel,
    required BuildContext context,
  }) async {
    final cacheKey = 'cluster_${label}_${riskLevel.name}';
    final cached = _clusterIconCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final backgroundColor = _getRiskColor(riskLevel);
    final textSize = label.length <= 2
        ? 18.0
        : label.length == 3
        ? 16.0
        : 14.0;

    final overlay = await NOverlayImage.fromWidget(
      context: context,
      size: const Size(56, 64),
      widget: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [backgroundColor, _darkenColor(backgroundColor, 0.15)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: textSize,
            fontWeight: FontWeight.w700,
          ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );

    _clusterIconCache[cacheKey] = overlay;
    return overlay;
  }

  void configureClusterMarker(
    NClusterInfo clusterInfo,
    NClusterMarker clusterMarker,
  ) {
    final context = _buildContext;
    final riskLevel = _resolveClusterRiskLevel(clusterInfo);
    final label = _formatClusterLabel(clusterInfo.size);
    final color = _getRiskColor(riskLevel);

    clusterMarker
      ..setSize(const NSize(56, 64))
      ..setAnchor(const NPoint(0.5, 0.5))
      ..setGlobalZIndex(1200)
      ..setIsForceShowIcon(true)
      ..setIsHideCollidedMarkers(false)
      ..setIsHideCollidedCaptions(false)
      ..setHideCollidedSymbols(false)
      ..setCaption(
        NOverlayCaption(
          text: label,
          textSize: label.length <= 2 ? 14 : 12,
          color: Colors.white,
          haloColor: Colors.transparent,
        ),
      );

    clusterMarker.setIconTintColor(color);

    if (context != null && context.mounted) {
      _getClusterMarkerIcon(
        label: label,
        riskLevel: riskLevel,
        context: context,
      ).then(
        (icon) => clusterMarker.setIcon(icon),
        onError: (error, stackTrace) {
          AppLogger.warning(
            '클러스터 마커 아이콘 생성 실패: ${clusterInfo.position}',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
        },
      );
    } else {
      clusterMarker.setIconTintColor(color);
    }

    clusterMarker.setOnTapListener((overlay) {
      _onClusterMarkerTapped(clusterInfo);
    });
  }

  NaverMapClusteringOptions buildClusteringOptions() {
    return NaverMapClusteringOptions(
      clusterMarkerBuilder: (info, marker) =>
          configureClusterMarker(info, marker),
    );
  }

  String _formatClusterLabel(int size) {
    if (size >= 1000) return '999+';
    if (size > 500) return '500+';
    return size.toString();
  }

  Color _getRiskColor(PotholeRiskLevel riskLevel) {
    switch (riskLevel) {
      case PotholeRiskLevel.high:
        return const Color(0xFFE53935);
      case PotholeRiskLevel.medium:
        return const Color(0xFFFB8C00);
      case PotholeRiskLevel.low:
        return const Color(0xFFFDD835);
    }
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final adjusted = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return adjusted.toColor();
  }

  PotholeRiskLevel _resolveClusterRiskLevel(NClusterInfo info) {
    PotholeRiskLevel maxLevel = PotholeRiskLevel.low;
    for (final child in info.children) {
      final tag = child.tags['riskLevel'];
      final level = PotholeRiskLevel.values.firstWhere(
        (value) => value.name == tag,
        orElse: () => PotholeRiskLevel.medium,
      );
      if (level.index > maxLevel.index) {
        maxLevel = level;
      }
    }
    return maxLevel;
  }

  String _mapStatusToAsset(PotholeStatus status) {
    switch (status) {
      case PotholeStatus.verificationRequired:
        return 'assets/images/general.png';
      case PotholeStatus.caution:
        return 'assets/images/waring.png';
      case PotholeStatus.danger:
        return 'assets/images/danger.png';
    }
  }

  /// 포트홀 마커 클릭 처리
  void _onPotholeMarkerTapped(PotholeMarker marker) {
    AppLogger.info('포트홀 마커 클릭: ${marker.id}');

    try {
      final context = _buildContext;
      AppLogger.info('Context null 여부: ${context == null}');

      if (context != null) {
        AppLogger.info('마커 타입: ${marker.type}');
        AppLogger.info('포트홀 데이터 null 여부: ${marker.potholeData == null}');

        // 개별 포트홀 마커인 경우만 처리
        if (marker.type == PotholeMarkerType.individual &&
            marker.potholeData != null) {
          final pothole = marker.potholeData!;
          AppLogger.info('포트홀 데이터 처리 시작: ${pothole.id}');

          final images = pothole.imageUrls.isNotEmpty
              ? pothole.imageUrls
              : _fallbackDetailImages;

          final description = pothole.description.isNotEmpty
              ? pothole.description
              : pothole.address.isNotEmpty
                  ? '도로 상태: ${pothole.address}'
                  : '도로에 포트홀이 발견되었습니다. 안전에 주의하세요.';

          final address = pothole.address.isNotEmpty
              ? pothole.address
              : _currentAddress.value;

          final potholeInfo = PotholeInfo(
            id: pothole.id,
            title: '포트홀 신고 #${pothole.id}',
            description: description,
            latitude: marker.position.latitude,
            longitude: marker.position.longitude,
            address: address,
            createdAt: pothole.reportedAt,
            images: images,
            status: pothole.status,
            firstReportedAt: pothole.reportedAt,
            latestReportedAt: pothole.reportedAt,
            reportCount: 1,
            complaintId: pothole.complaintId,
          );

          AppLogger.info('PotholeInfo 생성 완료, bottom sheet 표시 시도');

          // Context가 여전히 유효한지 확인
          if (context.mounted) {
            // 상세 정보 bottom sheet 표시
            PotholeDetailBottomSheet.show(context, potholeInfo)
                .then((_) {
                  AppLogger.info('Bottom sheet 표시 완료');
                })
                .catchError((error) {
                  AppLogger.error('Bottom sheet 표시 실패', error: error);
                  // 사용자에게 알림 (옵션)
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('포트홀 상세 정보를 불러올 수 없습니다')),
                  // );
                });
          } else {
            AppLogger.error('Context가 더 이상 유효하지 않음 (mounted = false)');
          }
        } else if (marker.type == PotholeMarkerType.cluster &&
            marker.clusterData != null) {
          AppLogger.info('클러스터 마커 클릭 - 목록 페이지로 이동');
          // 클러스터 마커인 경우 목록 페이지로 이동
          if (context.mounted) {
            context.go('/pothole-list');
          }
        } else {
          AppLogger.warning('처리할 수 없는 마커 타입 또는 데이터 없음');
        }
      } else {
        AppLogger.error('Context가 null입니다 - Bottom sheet를 표시할 수 없습니다');
        AppLogger.error('_buildContext 값: $_buildContext');
        AppLogger.error('마커 ID: ${marker.id}, 타입: ${marker.type}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('포트홀 마커 클릭 처리 중 오류', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onClusterMarkerTapped(NClusterInfo info) async {
    if (_mapController == null) return;

    try {
      final positions = info.children.map((child) => child.position).toList();
      if (positions.isEmpty) {
        AppLogger.warning('클러스터 정보에 자식 마커가 없습니다: ${info.size}');
        return;
      }

      late final NCameraUpdate cameraUpdate;
      if (positions.length == 1) {
        final currentZoom = _mapController!.nowCameraPosition.zoom;
        final targetZoom = (currentZoom + 1).clamp(0.0, 21.0).toDouble();
        cameraUpdate = NCameraUpdate.scrollAndZoomTo(
          target: positions.first,
          zoom: targetZoom,
        );
      } else {
        final bounds = NLatLngBounds.from(positions);
        cameraUpdate = NCameraUpdate.fitBounds(
          bounds,
          padding: const EdgeInsets.all(80),
        );
      }

      cameraUpdate.setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 500),
      );

      await _mapController!.updateCamera(cameraUpdate);
      AppLogger.info('클러스터 영역으로 카메라 이동: ${info.position}');
    } catch (e, stackTrace) {
      AppLogger.error('클러스터 마커 클릭 처리 중 오류', error: e, stackTrace: stackTrace);
    }
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
    AppLogger.info('줌 레벨 $zoomLevel 변경 감지 - 네이버 맵 클러스터링이 자동으로 처리됩니다');
  }

  /// API에서 포트홀 데이터 로드
  Future<List<PotholeMarker>> loadPotholeMarkersFromApi({
    double? latitude,
    double? longitude,
    double? distance,
  }) async {
    final targetLat = latitude ?? _currentPosition.value.latitude;
    final targetLng = longitude ?? _currentPosition.value.longitude;
    final searchDistance = distance ?? _defaultSearchDistance;

    AppLogger.info(
      'API 기반 포트홀 데이터 로드 시작 - lat: $targetLat, lng: $targetLng, distance: $searchDistance',
    );

    try {
      final potholes = await PotholeApiService.getPotholesByLocation(
        latitude: targetLat,
        longitude: targetLng,
        distance: searchDistance,
      );

      if (potholes.isEmpty) {
        AppLogger.warning('API에서 포트홀 데이터를 찾지 못했습니다');
        return [];
      }

      final markers = <PotholeMarker>[];
      for (final pothole in potholes) {
        try {
          markers.add(_buildMarkerFromPothole(pothole));
        } catch (e, stackTrace) {
          AppLogger.error(
            '포트홀 데이터를 마커로 변환하는 데 실패: ${pothole.id}',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      AppLogger.info('API에서 포트홀 마커 ${markers.length}개 로드 완료');
      return markers;
    } catch (e, stackTrace) {
      AppLogger.error(
        'API 기반 포트홀 데이터 로드 실패',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// API를 사용해 현재 표시 중인 포트홀 마커를 갱신
  Future<void> refreshPotholeMarkersFromApi({
    BuildContext? context,
    double? latitude,
    double? longitude,
    double? distance,
  }) async {
    try {
      // context를 async gap 전에 저장
      final savedContext = context;

      final markers = await loadPotholeMarkersFromApi(
        latitude: latitude,
        longitude: longitude,
        distance: distance,
      );

      if (markers.isEmpty) {
        AppLogger.warning('API에서 포트홀 마커가 없어 기존 마커를 제거합니다');
        _potholeMarkers.clear();
        await _clearPotholeMarkers();
        return;
      }

      // savedContext가 여전히 유효한 경우에만 사용
      if (savedContext != null && savedContext.mounted) {
        await addPotholeMarkers(markers, context: savedContext);
      } else {
        await addPotholeMarkers(markers);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'API 기반 포트홀 마커 갱신 실패',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  PotholeMarker _buildMarkerFromPothole(Pothole pothole) {
    final lat = pothole.latitude;
    final lng = pothole.longitude;

    if (lat.abs() > 90 || lng.abs() > 180) {
      throw ArgumentError('유효하지 않은 포트홀 좌표: ${pothole.id}');
    }

    String description = '제보된 포트홀입니다.';
    for (final candidate in [
      pothole.description,
      pothole.aiSummary,
      pothole.address,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        description = candidate.trim();
        break;
      }
    }

    final potholeData = PotholeData(
      id: pothole.id.toString(),
      latitude: lat,
      longitude: lng,
      riskLevel: _mapStatusToRiskLevel(pothole.status),
      description: description,
      reportedAt: pothole.createdAt,
      status: pothole.status,
      complaintId: pothole.complaintId?.toString(),
      imageUrls: pothole.images,
      address: pothole.address,
    );

    return PotholeMarker.individual(potholeData);
  }

  /// JSON 파일에서 포트홀 데이터 로드
  Future<List<PotholeMarker>> loadPotholeMarkersFromJson() async {
    final List<PotholeMarker> allMarkers = [];

    try {
      // 1. pothole_data.json 파일 로드 시도
      try {
        AppLogger.info('JSON 파일 로딩 시도: assets/data/pothole_data.json');
        final response1 = await rootBundle.loadString(
          'assets/data/pothole_data.json',
        );
        AppLogger.info('pothole_data.json 로딩 성공, 길이: ${response1.length}');

        final data1 = json.decode(response1);
        if (data1 is List) {
          AppLogger.info(
            'pothole_data.json: 배열 형태의 포트홀 데이터 ${data1.length}개 발견',
          );
          for (int i = 0; i < data1.length; i++) {
            try {
              final potholeData = data1[i];
              final pothole = PotholeData(
                id: potholeData['id']?.toString() ?? 'pothole_data_$i',
                latitude: (potholeData['latitude'] ?? 0.0).toDouble(),
                longitude:
                    (potholeData['langitude'] ??
                            potholeData['longitude'] ??
                            0.0)
                        .toDouble(),
                riskLevel: PotholeRiskLevel.high,
                description: potholeData['description'] ?? '',
                reportedAt:
                    DateTime.tryParse(potholeData['createdAt'] ?? '') ??
                    DateTime.now(),
                status: potholeData['status'] ?? PotholeStatus.danger,
                complaintId: potholeData['complaintId']?.toString(),
                imageUrls: _parseImageList(potholeData['images']),
                address: _parseOptionalString(potholeData['address']),
              );
              allMarkers.add(PotholeMarker.individual(pothole));
              AppLogger.info('pothole_data.json에서 포트홀 ${pothole.id} 파싱 완료');
            } catch (e) {
              AppLogger.error(
                'pothole_data.json 포트홀 데이터 파싱 실패: ${data1[i]}',
                error: e,
              );
            }
          }
        }
      } catch (e) {
        AppLogger.warning('pothole_data.json 로딩 실패: $e');
      }

      // 2. potholes.json 파일 로드 시도
      try {
        AppLogger.info('JSON 파일 로딩 시도: assets/data/potholes.json');
        final response2 = await rootBundle.loadString(
          'assets/data/potholes.json',
        );
        AppLogger.info('potholes.json 로딩 성공, 길이: ${response2.length}');

        final data2 = json.decode(response2);
        if (data2 is Map<String, dynamic>) {
          AppLogger.info(
            'potholes.json: 객체 형태의 JSON 데이터, 키들: ${data2.keys.toList()}',
          );

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
                AppLogger.error(
                  'potholes.json 포트홀 데이터 파싱 실패: $potholeJson',
                  error: e,
                );
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
                AppLogger.error(
                  'potholes.json 클러스터 데이터 파싱 실패: $clusterJson',
                  error: e,
                );
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
      status: json['status'] ?? PotholeStatus.verificationRequired,
      complaintId: json['complaintId']?.toString(),
      imageUrls: _parseImageList(json['images'] ?? json['imageUrls']),
      address: _parseOptionalString(json['address']),
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

  PotholeRiskLevel _mapStatusToRiskLevel(PotholeStatus status) {
    switch (status) {
      case PotholeStatus.danger:
        return PotholeRiskLevel.high;
      case PotholeStatus.caution:
        return PotholeRiskLevel.medium;
      case PotholeStatus.verificationRequired:
        return PotholeRiskLevel.low;
    }
  }

  List<String> _parseImageList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .where((element) => element != null)
          .map((element) => element.toString())
          .where((element) => element.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      if (value.contains(',')) {
        return value
            .split(',')
            .map((element) => element.trim())
            .where((element) => element.isNotEmpty)
            .toList();
      }
      return [value.trim()];
    }
    return const [];
  }

  String _parseOptionalString(dynamic value) {
    if (value == null) return '';
    final result = value.toString().trim();
    if (result.isEmpty || result.toLowerCase() == 'null') {
      return '';
    }
    return result;
  }

  /// 샘플 포트홀 데이터 생성 (테스트용 - fallback)
  List<PotholeMarker> generateSamplePotholeMarkers() {
    final currentPos = _currentPosition.value;

    final sampleData = [
      // 높은 위험도 포트홀들 (빨간색 마커)
      PotholeMarker.individual(
        PotholeData(
          id: 'high_p1',
          latitude: currentPos.latitude + 0.001,
          longitude: currentPos.longitude + 0.001,
          riskLevel: PotholeRiskLevel.high,
          description: '심각한 포트홀 - 차량 파손 위험',
          reportedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: PotholeStatus.danger,
          complaintId: 'HIGH-1001',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'high_p2',
          latitude: currentPos.latitude + 0.0015,
          longitude: currentPos.longitude - 0.0008,
          riskLevel: PotholeRiskLevel.high,
          description: '깊은 포트홀, 즉시 보수 필요',
          reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
          status: PotholeStatus.danger,
          complaintId: 'HIGH-1002',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'high_p3',
          latitude: currentPos.latitude - 0.0012,
          longitude: currentPos.longitude + 0.0018,
          riskLevel: PotholeRiskLevel.high,
          description: '대형 포트홀, 교통 통제 검토 필요',
          reportedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: PotholeStatus.danger,
          complaintId: 'HIGH-1003',
        ),
      ),

      // 중간 위험도 포트홀들 (주황색 마커)
      PotholeMarker.individual(
        PotholeData(
          id: 'medium_p1',
          latitude: currentPos.latitude - 0.001,
          longitude: currentPos.longitude + 0.0005,
          riskLevel: PotholeRiskLevel.medium,
          description: '중간 크기 포트홀',
          reportedAt: DateTime.now().subtract(const Duration(days: 3)),
          status: PotholeStatus.caution,
          complaintId: 'MED-1001',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'medium_p2',
          latitude: currentPos.latitude + 0.0008,
          longitude: currentPos.longitude - 0.0015,
          riskLevel: PotholeRiskLevel.medium,
          description: '도로면 손상, 보수 작업 예정',
          reportedAt: DateTime.now().subtract(
            const Duration(days: 1, hours: 12),
          ),
          status: PotholeStatus.caution,
          complaintId: 'MED-1002',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'medium_p3',
          latitude: currentPos.latitude - 0.0018,
          longitude: currentPos.longitude - 0.0005,
          riskLevel: PotholeRiskLevel.medium,
          description: '아스팔트 균열 확대',
          reportedAt: DateTime.now().subtract(const Duration(hours: 18)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'MED-1003',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'medium_p4',
          latitude: currentPos.latitude + 0.0005,
          longitude: currentPos.longitude + 0.0012,
          riskLevel: PotholeRiskLevel.medium,
          description: '차선 경계 포트홀',
          reportedAt: DateTime.now().subtract(const Duration(days: 4)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'MED-1004',
        ),
      ),

      // 낮은 위험도 포트홀들 (노란색 마커)
      PotholeMarker.individual(
        PotholeData(
          id: 'low_p1',
          latitude: currentPos.latitude + 0.0005,
          longitude: currentPos.longitude - 0.001,
          riskLevel: PotholeRiskLevel.low,
          description: '작은 포트홀',
          reportedAt: DateTime.now().subtract(const Duration(days: 5)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'LOW-1001',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'low_p2',
          latitude: currentPos.latitude - 0.0005,
          longitude: currentPos.longitude - 0.001,
          riskLevel: PotholeRiskLevel.low,
          description: '표면 거칠음',
          reportedAt: DateTime.now().subtract(const Duration(days: 6)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'LOW-1002',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'low_p3',
          latitude: currentPos.latitude + 0.002,
          longitude: currentPos.longitude - 0.0005,
          riskLevel: PotholeRiskLevel.low,
          description: '경미한 도로 손상',
          reportedAt: DateTime.now().subtract(const Duration(days: 7)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'LOW-1003',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'low_p4',
          latitude: currentPos.latitude - 0.002,
          longitude: currentPos.longitude + 0.0008,
          riskLevel: PotholeRiskLevel.low,
          description: '노면 표시선 근처 손상',
          reportedAt: DateTime.now().subtract(const Duration(days: 8)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'LOW-1004',
        ),
      ),
      PotholeMarker.individual(
        PotholeData(
          id: 'low_p5',
          latitude: currentPos.latitude + 0.0012,
          longitude: currentPos.longitude + 0.0015,
          riskLevel: PotholeRiskLevel.low,
          description: '인도 근처 작은 균열',
          reportedAt: DateTime.now().subtract(const Duration(days: 10)),
          status: PotholeStatus.verificationRequired,
          complaintId: 'LOW-1005',
        ),
      ),

      // 다양한 위험도 클러스터들
      PotholeMarker.cluster(
        PotholeCluster(
          id: 'cluster_high',
          latitude: currentPos.latitude - 0.002,
          longitude: currentPos.longitude - 0.002,
          count: 8,
          potholes: [
            PotholeData(
              id: 'cluster_high_1',
              latitude: currentPos.latitude - 0.002,
              longitude: currentPos.longitude - 0.002,
              riskLevel: PotholeRiskLevel.high,
              description: '클러스터 내 고위험 포트홀',
              reportedAt: DateTime.now(),
              status: PotholeStatus.danger,
            ),
          ],
        ),
      ),
      PotholeMarker.cluster(
        PotholeCluster(
          id: 'cluster_medium',
          latitude: currentPos.latitude + 0.0025,
          longitude: currentPos.longitude + 0.0025,
          count: 5,
          potholes: [
            PotholeData(
              id: 'cluster_med_1',
              latitude: currentPos.latitude + 0.0025,
              longitude: currentPos.longitude + 0.0025,
              riskLevel: PotholeRiskLevel.medium,
              description: '클러스터 내 중위험 포트홀',
              reportedAt: DateTime.now(),
              status: PotholeStatus.caution,
            ),
          ],
        ),
      ),
      PotholeMarker.cluster(
        PotholeCluster(
          id: 'cluster_low',
          latitude: currentPos.latitude - 0.003,
          longitude: currentPos.longitude + 0.003,
          count: 12,
          potholes: [
            PotholeData(
              id: 'cluster_low_1',
              latitude: currentPos.latitude - 0.003,
              longitude: currentPos.longitude + 0.003,
              riskLevel: PotholeRiskLevel.low,
              description: '클러스터 내 저위험 포트홀',
              reportedAt: DateTime.now(),
              status: PotholeStatus.verificationRequired,
            ),
          ],
        ),
      ),
    ];

    return sampleData;
  }

  /// 맵 인스턴스 정리 (페이지를 떠날 때)
  /// Singleton이므로 ValueNotifier는 dispose하지 않음
  void resetMapInstance() {
    _isMapReady.value = false;
    _potholeMarkers.clear();
    _activeMarkers.clear();
    _markerIconCache.clear();
    _clusterIconCache.clear();
    _currentLocationOverlayImage = null;
    _mapController = null;
    _buildContext = null;
    AppLogger.info('MapController 인스턴스 리셋 완료');
  }

  /// 완전한 메모리 해제 (앱 종료 시에만 사용)
  void dispose() {
    _isMapReady.dispose();
    _currentPosition.dispose();
    _currentAddress.dispose();
    _potholeMarkers.clear();
    _activeMarkers.clear();
    _markerIconCache.clear();
    _clusterIconCache.clear();
    _currentLocationOverlayImage = null;
    _mapController = null;
    _buildContext = null;
  }
}
