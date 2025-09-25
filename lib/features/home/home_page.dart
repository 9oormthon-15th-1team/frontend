import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_config.dart';
import '../../core/services/debug/debug_helper.dart';
import '../../core/services/logging/app_logger.dart';
import 'map_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, RouteAware {
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
      await _mapController.getCurrentLocation(moveMap: false);
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
    } catch (e) {
      AppLogger.error('맵 초기화 실패', error: e);
      setState(() {
        _isInitialized = false;
      });
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
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: _buildCurrentLocationButton(),
          ),

          // 확대/축소 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            right: 16,
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
          zoom: 14,
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
        _mapController.setMapController(controller);
        AppLogger.info('네이버 맵 준비 완료');
      },
      onMapTapped: (NPoint point, NLatLng latLng) {
        AppLogger.info('맵 탭: ${latLng.latitude}, ${latLng.longitude}');
      },
      onCameraChange: (NCameraUpdateReason reason, bool animated) {
        // 카메라 변경시 로그 (너무 많이 호출되므로 성능상 비활성화)
        // AppLogger.debug('카메라 변경: $reason');
      },
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
              const Icon(Icons.location_on, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '현재 위치',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
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
          onPressed: isReady ? () => _mapController.getCurrentLocation() : null,
          backgroundColor: isReady ? Colors.white : Colors.grey,
          foregroundColor: isReady ? Colors.blue : Colors.white,
          elevation: 4,
          mini: true,
          child: const Icon(Icons.my_location),
        );
      },
    );
  }

  Widget _buildZoomButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mapController.isMapReadyNotifier,
      builder: (context, isReady, child) {
        return Column(
          children: [
            // 확대 버튼
            Container(
              decoration: BoxDecoration(
                color: isReady ? Colors.white : Colors.grey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReady ? () => _mapController.zoomIn() : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.add,
                      color: isReady ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // 구분선
            Container(height: 1, width: 40, color: Colors.grey[300]),
            // 축소 버튼
            Container(
              decoration: BoxDecoration(
                color: isReady ? Colors.white : Colors.grey,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReady ? () => _mapController.zoomOut() : null,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.remove,
                      color: isReady ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 디버깅 버튼 (왼쪽)
        if (AppConfig.enableDebugTools)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () => DebugHelper.logDeviceInfo(context),
              tooltip: 'Debug Info',
            ),
          )
        else
          const SizedBox(width: 56), // 디버그 버튼이 없을 때 공간 유지
        // 갤러리 이동 버튼 (오른쪽)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              context.push('/gallery');
            },
            tooltip: 'Gallery',
          ),
        ),
      ],
    );
  }
}
