import 'package:flutter/material.dart';
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

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
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
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('네이버 맵'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          if (AppConfig.enableDebugTools)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => DebugHelper.logDeviceInfo(context),
              tooltip: 'Log Device Info',
            ),
        ],
      ),
      body: Stack(
        children: [
          // 네이버 맵 (전체 화면)
          if (_isInitialized)
            _buildNaverMap()
          else
            _buildLoadingView(),

          // 현재 위치 버튼
          Positioned(
            top: 16,
            right: 16,
            child: _buildCurrentLocationButton(),
          ),

          // 확대/축소 버튼
          Positioned(
            top: 80,
            right: 16,
            child: _buildZoomButtons(),
          ),

          // 하단 주소 표시 카드만 유지
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildLocationCard(),
          ),
        ],
      ),
      // 하단 네비게이션 또는 빠른 이동 버튼
      bottomNavigationBar: _buildQuickLocationBar(),
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

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ValueListenableBuilder<String>(
          valueListenable: _mapController.currentAddressNotifier,
          builder: (context, address, child) {
            return ValueListenableBuilder<NLatLng>(
              valueListenable: _mapController.currentPositionNotifier,
              builder: (context, position, child) {
                return Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
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
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '위도: ${position.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '경도: ${position.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => _mapController.getCurrentLocation(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
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
            Container(
              height: 1,
              width: 40,
              color: Colors.grey[300],
            ),
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

  Widget _buildQuickLocationBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mapController.isMapReadyNotifier,
      builder: (context, isReady, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLocationButton('시청', Icons.account_balance,
                isReady ? _mapController.moveToSeoulCityHall : null),
              _buildLocationButton('강남', Icons.train,
                isReady ? _mapController.moveToGangnam : null),
              _buildLocationButton('홍대', Icons.nightlife,
                isReady ? _mapController.moveToHongdae : null),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationButton(String label, IconData icon, VoidCallback? onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 28,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}