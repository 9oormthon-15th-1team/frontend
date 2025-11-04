import 'package:flutter/material.dart';
import '../../core/models/pothole.dart';
import '../../core/models/pothole_status.dart';
import '../../core/services/api/pothole_api_service.dart';
import '../../widgets/loading/loading_widget.dart';
import '../home/map_controller.dart';
import 'widgets/address_input_widget.dart';
import 'widgets/pothole_list_item.dart';

class PotholeListPage extends StatefulWidget {
  const PotholeListPage({super.key});

  @override
  State<PotholeListPage> createState() => _PotholeListPageState();
}

class _PotholeListPageState extends State<PotholeListPage> {
  List<Pothole> potholes = [];
  List<Pothole> filteredPotholes = [];
  bool isLoading = true;
  String? error;

  // Singleton MapController 인스턴스 사용
  final MapController _mapController = MapController();
  String _currentAddress = '위치를 가져오는 중...';

  @override
  void initState() {
    super.initState();
    // MapController의 주소 변경을 구독
    _mapController.currentAddressNotifier.addListener(_updateAddress);
    // 초기값 설정
    _currentAddress = _mapController.currentAddressNotifier.value;
    _loadPotholes();
  }

  @override
  void dispose() {
    // 리스너 제거
    _mapController.currentAddressNotifier.removeListener(_updateAddress);
    super.dispose();
  }

  /// MapController의 주소가 변경되면 호출됨
  void _updateAddress() {
    if (mounted) {
      setState(() {
        _currentAddress = _mapController.currentAddressNotifier.value;
      });
    }
  }

  Future<void> _loadPotholes() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedPotholes = await PotholeApiService.getPotholes();

      setState(() {
        potholes = fetchedPotholes;
        filteredPotholes = fetchedPotholes;
        isLoading = false;
      });
    } catch (e) {
      // API 실패 시 목업 데이터 사용
      setState(() {
        potholes = _getMockPotholes();
        filteredPotholes = _getMockPotholes();
        isLoading = false;
        error = null; // 목업 데이터로 대체하므로 에러 없음
      });
    }
  }

  List<Pothole> _getMockPotholes() {
    return [
      Pothole(
        id: 1,
        latitude: 33.4996,
        longitude: 126.5312,
        status: PotholeStatus.danger,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        description: '도로에 큰 구멍이 있어 차량 통행에 위험합니다.',
        address: '제주시 건입동 건입동로 348',
        aiSummary:
            'AI가 분석한 결과, 차량 통행에 매우 위험한 큰 포트홀로 즉시 보수가 필요한 상태입니다. 우회 도로 이용을 권장합니다.',
      ),
      Pothole(
        id: 2,
        latitude: 33.5012,
        longitude: 126.5298,
        status: PotholeStatus.caution,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        description: '중간 크기의 포트홀이 발견되었습니다.',
        address: '제주시 이도1동 중앙로 125',
        aiSummary: '중간 정도의 위험도를 가진 포트홀입니다. 현재 처리 중이므로 주의하여 통행하시기 바랍니다.',
      ),
      Pothole(
        id: 3,
        latitude: 33.4988,
        longitude: 126.5325,
        status: PotholeStatus.verificationRequired,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        description: '작은 구멍이지만 주의가 필요합니다.',
        address: '제주시 용담2동 용문로 89',
        aiSummary: '작은 규모의 포트홀로 보수가 완료되었습니다. 안전하게 통행 가능합니다.',
      ),
      Pothole(
        id: 4,
        latitude: 33.5023,
        longitude: 126.5301,
        status: PotholeStatus.danger,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        description: '아스팔트가 패여 있어 매우 위험한 상태입니다.',
        address: '제주시 일도1동 관덕로 45',
        aiSummary: '아스팔트 손상이 심각한 고위험 구간입니다. 차량 파손 위험이 높으니 속도를 줄여 통행하세요.',
      ),
      Pothole(
        id: 5,
        latitude: 33.4975,
        longitude: 126.5340,
        status: PotholeStatus.caution,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        description: '비가 온 후 더 심해진 포트홀입니다.',
        address: '제주시 삼도2동 삼무로 234',
        aiSummary: '강우로 인해 악화된 포트홀입니다. 우천 시 더욱 주의가 필요하며 현재 보수 작업이 진행 중입니다.',
      ),
      Pothole(
        id: 6,
        latitude: 33.5035,
        longitude: 126.5285,
        status: PotholeStatus.danger,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        description: '도로 가장자리에 작은 구멍이 있습니다.',
        address: '제주시 노형동 노연로 167',
        aiSummary: '도로 가장자리의 소규모 포트홀입니다. 차선 변경 시 주의하시면 안전하게 통행 가능합니다.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AddressInputWidget(
            address: _currentAddress,
            onRefresh: _loadPotholes,
          ),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading potholes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPotholes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // if (filteredPotholes.isEmpty) {
    //   if (potholes.isNotEmpty) {
    //     return const Center(child: Text('선택한 필터 조건에 맞는 포트홀이 없습니다.'));
    //   }
    //   return const Center(child: Text('No potholes found'));
    // }

    return RefreshIndicator(
      onRefresh: _loadPotholes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: filteredPotholes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pothole = filteredPotholes[index];
          return PotholeListItem(
            pothole: pothole,
            onDetailTap: () => _onDetailTap(pothole),
            onNavigateTap: () => _onNavigateTap(pothole),
          );
        },
      ),
    );
  }

  void _onDetailTap(Pothole pothole) {
    // TODO: Navigate to detail page
  }

  void _onNavigateTap(Pothole pothole) {
    // TODO: Navigate to maps with pothole location
  }


  // void _applySortingAndFiltering() {
  //   List<Pothole> result = List.from(potholes);

  //   // 필터링 적용
  //   if (_selectedSeverityFilter != null) {
  //     result = result
  //         .where(
  //           (pothole) =>
  //               _getSeverityDisplayName(pothole.severity) ==
  //               _selectedSeverityFilter,
  //         )
  //         .toList();
  //   }

  //   if (_selectedStatusFilter != null) {
  //     result = result
  //         .where((pothole) => pothole.status == _selectedStatusFilter)
  //         .toList();
  //   }

  //   // 정렬 적용
  //   switch (_currentSortType) {
  //     case SortType.distance:
  //       result.sort(
  //         (a, b) =>
  //             _calculateDistanceValue(a).compareTo(_calculateDistanceValue(b)),
  //       );
  //       break;
  //     case SortType.severity:
  //       result.sort(
  //         (a, b) => _getSeverityPriority(
  //           b.severity,
  //         ).compareTo(_getSeverityPriority(a.severity)),
  //       );
  //       break;
  //     case SortType.recent:
  //       result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //       break;
  //     case SortType.status:
  //       result.sort(
  //         (a, b) => _getStatusPriority(
  //           a.status,
  //         ).compareTo(_getStatusPriority(b.status)),
  //       );
  //       break;
  //   }

  //   filteredPotholes = result;
  // }



}
