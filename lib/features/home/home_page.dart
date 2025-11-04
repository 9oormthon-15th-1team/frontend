import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:porthole_in_jeju/features/pothole_report/screens/photo_selection_screen.dart';

import '../../core/services/logging/app_logger.dart';
import '../../core/state/plus_menu_state.dart';
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
  Timer? _cameraChangeDebounce;
  bool _isPlusMenuExpanded = false;
  static const double _actionButtonSize = 48;
  static const double _actionIconSize = _actionButtonSize * 0.6;
  static const double _actionButtonRightPadding = 16;
  void _onPlusMenuStateChanged() {
    final isExpanded = PlusMenuState.isExpanded.value;
    if (_isPlusMenuExpanded == isExpanded) {
      return;
    }

    if (mounted) {
      setState(() {
        _isPlusMenuExpanded = isExpanded;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PlusMenuState.isExpanded.addListener(_onPlusMenuStateChanged);
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
      if (!mounted) return;
      await _loadPotholeMarkers();
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
    if (!mounted) return;

    try {
      final markers = await _mapController.loadPotholeMarkersFromApi();
      if (!mounted) return;

      if (markers.isNotEmpty) {
        await _mapController.addPotholeMarkers(markers, context: context);
        AppLogger.info('포트홀 마커 로드 완료 (API)');
        return;
      }
      AppLogger.warning('API에서 포트홀 데이터를 찾지 못해 로컬 데이터로 대체합니다');
    } catch (e) {
      AppLogger.error('포트홀 마커 API 로드 실패, 로컬 데이터 사용', error: e);
    }

    try {
      final fallbackMarkers = await _mapController.loadPotholeMarkersFromJson();
      if (!mounted) return;
      await _mapController.addPotholeMarkers(fallbackMarkers, context: context);
      AppLogger.info('포트홀 마커 로딩 완료 (로컬 데이터)');
    } catch (e) {
      AppLogger.error('포트홀 마커 로컬 데이터 로드 실패', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraChangeDebounce?.cancel();
    // Singleton이므로 dispose 대신 resetMapInstance 사용
    _mapController.resetMapInstance();
    PlusMenuState.isExpanded.removeListener(_onPlusMenuStateChanged);
    PlusMenuState.isExpanded.value = false;
    super.dispose();
  }

  void _togglePlusMenu() {
    final nextValue = !_isPlusMenuExpanded;
    setState(() {
      _isPlusMenuExpanded = nextValue;
    });
    PlusMenuState.isExpanded.value = nextValue;
  }

  void _collapsePlusMenu() {
    if (!_isPlusMenuExpanded) return;
    setState(() {
      _isPlusMenuExpanded = false;
    });
    PlusMenuState.isExpanded.value = false;
  }

  void _handlePlusMenuLocation() {
    _collapsePlusMenu();
    if (!_mapController.isMapReadyNotifier.value) return;
    unawaited(
      _mapController.moveToCurrentLocation(context).then((_) async {
        if (!mounted) return;
        await _loadPotholeMarkers();
      }).catchError((error, stackTrace) {
        AppLogger.error('현재 위치 이동 실패', error: error, stackTrace: stackTrace);
      }),
    );
  }

  void _handlePlusMenuCamera() {
    _collapsePlusMenu();
    _showPhotoSelectionScreen();
  }

  Widget _buildPlusMenuAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: _actionButtonSize,
      height: _actionButtonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_actionButtonSize / 2),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFFFF5E3A),
              size: _actionIconSize,
            ),
          ),
        ),
      ),
    );
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

          // 플러스 메뉴 오버레이
          if (_isPlusMenuExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapsePlusMenu,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),

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
            right: _actionButtonRightPadding,
            child: _buildCurrentLocationButton(),
          ),

          // 확대/축소 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 140,
            right: _actionButtonRightPadding,
            child: _buildZoomButtons(),
          ),

          // + 버튼
          Positioned(
            bottom: 20,
            right: _actionButtonRightPadding,
            child: _buildPlusButton(),
          ),

          // 하단 버튼들
          Positioned(
            bottom: 20,
            // left: 16,
            right: _actionButtonRightPadding + _actionButtonSize + 8,
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
      clusterOptions: _mapController.buildClusteringOptions(),
      onMapReady: (NaverMapController controller) {
        _mapController.setMapController(controller, context);
        AppLogger.info('네이버 맵 준비 완료');
      },
      onMapTapped: (NPoint point, NLatLng latLng) {
        AppLogger.info('맵 탭: ${latLng.latitude}, ${latLng.longitude}');
      },
      onCameraChange: (NCameraUpdateReason reason, bool animated) async {
        if (_mapController.mapController == null) return;

        // 팬/줌 제스처 또는 컨트롤 버튼 조작에만 반응
        if (reason != NCameraUpdateReason.gesture &&
            reason != NCameraUpdateReason.control) {
          return;
        }

        _cameraChangeDebounce?.cancel();
        _cameraChangeDebounce = Timer(
          const Duration(milliseconds: 300),
          () async {
            final controller = _mapController.mapController;
            if (controller == null) return;

            try {
              final cameraPosition = await controller.getCameraPosition();
              await _mapController.updateMarkersForZoomLevel(
                cameraPosition.zoom,
              );
            } catch (e) {
              AppLogger.warning('카메라 위치 조회 실패', error: e);
            }
          },
        );
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
        return SizedBox(
          width: _actionButtonSize,
          height: _actionButtonSize,
          child: FloatingActionButton(
            heroTag: 'current_location_button',
            onPressed: isReady
                ? () => _mapController.moveToCurrentLocation(context)
                : null,
            backgroundColor: isReady ? Colors.white : Colors.grey,
            foregroundColor: isReady ? Colors.blue : Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_actionButtonSize / 2),
            ),
            child: SvgPicture.asset(
              'assets/svg/locationButton.svg',
              width: _actionIconSize * 1.5,
              height: _actionIconSize * 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return DecoratedBox(
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
      // child: ClipOval(
      //   child: SizedBox(
      //     width: 46,
      //     height: 46,
      //     child: IconButton(
      //       padding: EdgeInsets.zero,
      //       constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      //       iconSize: 48,
      //       icon: SvgPicture.asset(
      //         'assets/svg/cameraButton.svg',
      //         width: 48,
      //         height: 48,
      //         fit: BoxFit.cover,
      //       ),
      //       onPressed: () {
      //         _showPhotoSelectionScreen();
      //       },
      //       tooltip: 'Gallery',
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildPlusButton() {
    return SizedBox(
      width: _actionButtonSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _actionButtonSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _isPlusMenuExpanded
                  ? Container(
                      key: const ValueKey('plus-menu'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          _actionButtonSize / 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlusMenuAction(
                            icon: Icons.location_on,
                            onTap: _handlePlusMenuLocation,
                          ),
                          const SizedBox(height: 4),
                          _buildPlusMenuAction(
                            icon: Icons.camera_alt,
                            onTap: _handlePlusMenuCamera,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(height: 0),
            ),
          ),
          Container(
            width: _actionButtonSize,
            height: _actionButtonSize,
            decoration: BoxDecoration(
              color: _isPlusMenuExpanded
                  ? Colors.white
                  : const Color(0xFFFF5E3A),
              borderRadius: BorderRadius.circular(_actionButtonSize / 2),
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
              onPressed: _togglePlusMenu,
              icon: Icon(
                _isPlusMenuExpanded ? Icons.close : Icons.add,
                color: _isPlusMenuExpanded
                    ? const Color(0xFFFF5E3A)
                    : Colors.white,
                size: _actionIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mapController.isMapReadyNotifier,
      builder: (context, isReady, child) {
        return SizedBox(
          width: _actionButtonSize,
          child: DecoratedBox(
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
                  splashRadius: _actionButtonSize / 2,
                ),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.grey[200],
                ),
                IconButton(
                  onPressed: isReady ? () => _mapController.zoomOut() : null,
                  icon: Icon(
                    Icons.remove,
                    color: isReady ? Colors.black87 : Colors.grey[400],
                  ),
                  splashRadius: _actionButtonSize / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 포트홀 신고 bottom sheet 표시
  void _showPhotoSelectionScreen() {
    _collapsePlusMenu();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
          child: const PhotoSelectionScreen(),
        ),
      ),
    );
  }
}
