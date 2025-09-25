import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_config.dart';
import '../../core/services/debug/debug_helper.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
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
            top: MediaQuery.of(context).padding.top + 75,
            right: 13,
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
                    // const Text(
                    //   '현재 위치',
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                    // const SizedBox(height: 2),
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
          onPressed: isReady
              ? () => _mapController.getCurrentLocation(moveMap: true)
              : null,
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
              _showPotholeReportBottomSheet();
            },
            tooltip: 'Gallery',
          ),
        ),
      ],
    );
  }

  /// 포트홀 신고 bottom sheet 표시
  void _showPotholeReportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPotholeReportBottomSheet(),
    );
  }

  /// 포트홀 신고 bottom sheet UI
  Widget _buildPotholeReportBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '사진 촬영',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // 진행률 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 카메라 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // 메인 텍스트
          const Text(
            '포트홀 사진을 촬영해주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          // 서브 텍스트
          const Text(
            '포트홀이 잘 보이도록 촬영해주세요.\n여러 장 촬영하면 더 정확한 신고가 가능합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          const Spacer(),

          // 버튼들
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // 카메라로 촬영 버튼
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePhotoWithCamera,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          '카메라로 촬영',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 갤러리 선택 버튼
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectFromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          '갤러리 선택',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 사진을 선택해주세요 버튼 (비활성화 상태)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // 비활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '사진을 선택해주세요',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 카메라로 사진 촬영
  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        if (mounted) {
          Navigator.pop(context);
          AppLogger.info('사진 촬영 완료: ${photo.path}');

          // 사진 촬영 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진이 촬영되었습니다: ${photo.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 다음 단계로 이동 (추후 구현)
        // TODO: 포트홀 상세 정보 입력 페이지로 이동
      } else {
        AppLogger.info('사진 촬영 취소됨');
      }
    } catch (e) {
      AppLogger.error('카메라 촬영 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 갤러리에서 사진 선택
  Future<void> _selectFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        if (mounted) {
          Navigator.pop(context);
          AppLogger.info('갤러리에서 사진 선택 완료: ${photo.path}');

          // 사진 선택 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진이 선택되었습니다: ${photo.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 다음 단계로 이동 (추후 구현)
        // TODO: 포트홀 상세 정보 입력 페이지로 이동
      } else {
        AppLogger.info('사진 선택 취소됨');
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      AppLogger.error('갤러리에서 사진 선택 실패', error: e);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('갤러리 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
