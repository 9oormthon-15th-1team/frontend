import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/logging/app_logger.dart';
import 'map_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  final MapController _mapController = MapController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 활성화될 때 현재 위치 업데이트
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _updateCurrentLocation();
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      // 페이지 복귀 시에는 맵을 이동하지 않고 위치만 업데이트
      if (!mounted) return;
      await _mapController.getCurrentLocation(context: context, moveMap: false);
      AppLogger.info('현재 위치 업데이트 완료');
    } catch (e) {
      AppLogger.error('현재 위치 업데이트 실패', error: e);
    }
  }

  Future<void> _initializeMap() async {
    try {
      await MapController.initialize();
      setState(() {
        _isInitialized = true;
      });

      // 맵 초기화 후 포트홀 마커 추가 (충분한 지연을 두고)
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _isInitialized) {
          _loadPotholeMarkers();
        }
      });
    } catch (e) {
      AppLogger.error('맵 초기화 실패', error: e);
      setState(() {
        _isInitialized = false;
      });
    }
  }

  /// 포트홀 마커 로드
  Future<void> _loadPotholeMarkers() async {
    try {
      // JSON 파일에서 포트홀 데이터 로드
      final markers = await _mapController.loadPotholeMarkersFromJson();
      if (mounted) {
        await _mapController.addPotholeMarkers(markers, context: context);
        AppLogger.info('포트홀 마커 로드 완료');
      }
    } catch (e) {
      AppLogger.error('포트홀 마커 로드 실패', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Container(), // 빈 타이틀
        actions: [],
      ),
      body: Stack(
        children: [
          // 네이버 맵 (전체 화면)
          if (_isInitialized) _buildNaverMap() else _buildLoadingView(),

          // 상단 현재 위치 표시
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildCurrentLocationCard(),
          ),

          // 현재 위치 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 75,
            right: 13,
            child: _buildCurrentLocationButton(),
          ),

          // 확대/축소 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 140,
            right: 13,
            child: _buildZoomButtons(),
          ),

          // 하단 버튼들
          Positioned(
            bottom: 20,
            // left: 16,
            right: 16,
            child: _buildBottomButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildNaverMap() {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: _mapController.currentPosition,
          zoom: 15, // 100m 기준 줌 레벨 (15가 약 100m)
        ),
        locale: const Locale('ko'),
        mapType: NMapType.basic,
        activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
        rotationGesturesEnable: true,
        scrollGesturesEnable: true,
        tiltGesturesEnable: true,
        zoomGesturesEnable: true,
        stopGesturesEnable: true,
      ),
      onMapReady: (NaverMapController controller) {
        _mapController.setMapController(controller, context);
        AppLogger.info('네이버 맵 준비 완료');
      },
      onMapTapped: (NPoint point, NLatLng latLng) {
        AppLogger.info('맵 탭: ${latLng.latitude}, ${latLng.longitude}');
      },
      onCameraChange: null,
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('네이버 맵을 로딩 중입니다...'),
          SizedBox(height: 8),
          Text(
            'API 키가 설정되지 않은 경우\nlib/core/constants/api_keys.dart에서\nNaver Map Client ID를 설정하세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return ValueListenableBuilder<String>(
      valueListenable: _mapController.currentAddressNotifier,
      builder: (context, address, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/nowLocationInfo.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      address.isEmpty ? '위치를 가져오는 중...' : address,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentLocationButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mapController.isMapReadyNotifier,
      builder: (context, isReady, child) {
        return FloatingActionButton(
          onPressed: isReady
              ? () => _mapController.moveToCurrentLocation(context)
              : null,
          backgroundColor: isReady ? Colors.white : Colors.grey,
          foregroundColor: isReady ? Colors.blue : Colors.white,
          elevation: 4,
          mini: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: SvgPicture.asset(
            'assets/svg/locationButton.svg',
            width: 100,
            height: 100,
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 디버깅 버튼 (왼쪽)
        // if (AppConfig.enableDebugTools)
        //   Container(
        //     width: 48,
        //     height: 48,
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(50),
        //       boxShadow: [
        //         BoxShadow(
        //           color: Colors.black.withValues(alpha: 0.2),
        //           spreadRadius: 1,
        //           blurRadius: 4,
        //           offset: const Offset(0, 2),
        //         ),
        //       ],
        //     ),
        //     child: IconButton(
        //       icon: const Icon(Icons.bug_report, color: Colors.orange),
        //       onPressed: () => DebugHelper.logDeviceInfo(context),
        //       tooltip: 'Debug Info',
        //     ),
        //   )
        // else
        //   const SizedBox(width: 56), // 디버그 버튼이 없을 때 공간 유지
        // 갤러리 이동 버튼 (오른쪽)
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                iconSize: 48,
                icon: SvgPicture.asset(
                  'assets/svg/cameraButton.svg',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
                onPressed: () {
                  _showPhotoSelectionScreen();
                },
                tooltip: 'Gallery',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mapController.isMapReadyNotifier,
      builder: (context, isReady, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isReady ? () => _mapController.zoomIn() : null,
                icon: Icon(
                  Icons.add,
                  color: isReady ? Colors.black87 : Colors.grey[400],
                ),
                splashRadius: 22,
              ),
              Container(height: 1, width: 42, color: Colors.grey[200]),
              IconButton(
                onPressed: isReady ? () => _mapController.zoomOut() : null,
                icon: Icon(
                  Icons.remove,
                  color: isReady ? Colors.black87 : Colors.grey[400],
                ),
                splashRadius: 22,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 포트홀 신고 bottom sheet 표시
  void _showPhotoSelectionScreen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '포트홀 신고',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/photo-selection');
                },
                child: const Text('사진 촬영하러 가기'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
