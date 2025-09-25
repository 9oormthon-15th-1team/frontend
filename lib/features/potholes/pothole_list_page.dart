import 'package:flutter/material.dart';
import '../../core/models/pothole.dart';
import '../../core/services/api/pothole_api_service.dart';
import '../../widgets/loading/loading_widget.dart';
import 'widgets/address_input_widget.dart';
import 'widgets/pothole_list_item.dart';
import 'widgets/category_filter_widget.dart';

class PotholeListPage extends StatefulWidget {
  const PotholeListPage({super.key});

  @override
  State<PotholeListPage> createState() => _PotholeListPageState();
}

enum SortType {
  distance('거리순'),
  severity('심각도순'),
  recent('최신순'),
  status('상태순');

  const SortType(this.displayName);
  final String displayName;
}

class _PotholeListPageState extends State<PotholeListPage> {
  List<Pothole> potholes = [];
  List<Pothole> filteredPotholes = [];
  bool isLoading = true;
  String? error;
  String _currentAddress = '제주특별자치도 제주시 이도2동';
  SortType _currentSortType = SortType.distance;
  String? _selectedSeverityFilter;
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadPotholes();
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
        _applySortingAndFiltering();
        isLoading = false;
      });
    } catch (e) {
      // API 실패 시 목업 데이터 사용
      setState(() {
        potholes = _getMockPotholes();
        _applySortingAndFiltering();
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
        severity: 'high',
        status: '신고됨',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        description: '도로에 큰 구멍이 있어 차량 통행에 위험합니다.',
      ),
      Pothole(
        id: 2,
        latitude: 33.5012,
        longitude: 126.5298,
        severity: 'medium',
        status: '처리중',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        description: '중간 크기의 포트홀이 발견되었습니다.',
      ),
      Pothole(
        id: 3,
        latitude: 33.4988,
        longitude: 126.5325,
        severity: 'low',
        status: '완료',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        description: '작은 구멍이지만 주의가 필요합니다.',
      ),
      Pothole(
        id: 4,
        latitude: 33.5023,
        longitude: 126.5301,
        severity: 'high',
        status: '신고됨',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        description: '아스팔트가 패여 있어 매우 위험한 상태입니다.',
      ),
      Pothole(
        id: 5,
        latitude: 33.4975,
        longitude: 126.5340,
        severity: 'medium',
        status: '처리중',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        description: '비가 온 후 더 심해진 포트홀입니다.',
      ),
      Pothole(
        id: 6,
        latitude: 33.5035,
        longitude: 126.5285,
        severity: 'low',
        status: '신고됨',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        description: '도로 가장자리에 작은 구멍이 있습니다.',
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
            onAddressChanged: (newAddress) {
              setState(() {
                _currentAddress = newAddress;
              });
            },
          ),
          CategoryFilterWidget(
            currentSortType: _currentSortType,
            selectedSeverityFilter: _selectedSeverityFilter,
            selectedStatusFilter: _selectedStatusFilter,
            onSortChanged: _onSortChanged,
            onSeverityFilterChanged: _onSeverityFilterChanged,
            onStatusFilterChanged: _onStatusFilterChanged,
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

    if (filteredPotholes.isEmpty) {
      if (potholes.isNotEmpty) {
        return const Center(child: Text('선택한 필터 조건에 맞는 포트홀이 없습니다.'));
      }
      return const Center(child: Text('No potholes found'));
    }

    return RefreshIndicator(
      onRefresh: _loadPotholes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPotholes.length,
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

  void _onSortChanged(SortType sortType) {
    setState(() {
      _currentSortType = sortType;
      _applySortingAndFiltering();
    });
  }

  void _onSeverityFilterChanged(String? severity) {
    setState(() {
      _selectedSeverityFilter = severity;
      _applySortingAndFiltering();
    });
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatusFilter = status;
      _applySortingAndFiltering();
    });
  }

  void _applySortingAndFiltering() {
    List<Pothole> result = List.from(potholes);

    // 필터링 적용
    if (_selectedSeverityFilter != null) {
      result = result
          .where(
            (pothole) =>
                _getSeverityDisplayName(pothole.severity) ==
                _selectedSeverityFilter,
          )
          .toList();
    }

    if (_selectedStatusFilter != null) {
      result = result
          .where((pothole) => pothole.status == _selectedStatusFilter)
          .toList();
    }

    // 정렬 적용
    switch (_currentSortType) {
      case SortType.distance:
        result.sort(
          (a, b) =>
              _calculateDistanceValue(a).compareTo(_calculateDistanceValue(b)),
        );
        break;
      case SortType.severity:
        result.sort(
          (a, b) => _getSeverityPriority(
            b.severity,
          ).compareTo(_getSeverityPriority(a.severity)),
        );
        break;
      case SortType.recent:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.status:
        result.sort(
          (a, b) => _getStatusPriority(
            a.status,
          ).compareTo(_getStatusPriority(b.status)),
        );
        break;
    }

    filteredPotholes = result;
  }

  double _calculateDistanceValue(Pothole pothole) {
    // 목업 거리 계산 (실제로는 현재 위치와의 거리를 계산해야 함)
    return pothole.id * 0.3 + 1.5;
  }

  int _getSeverityPriority(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return 3;
      case 'medium':
      case 'moderate':
        return 2;
      case 'low':
      case 'minor':
        return 1;
      default:
        return 0;
    }
  }

  int _getStatusPriority(String status) {
    switch (status) {
      case '신고됨':
        return 1;
      case '처리중':
        return 2;
      case '완료':
        return 3;
      default:
        return 0;
    }
  }

  String _getSeverityDisplayName(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return '위험';
      case 'medium':
      case 'moderate':
        return '주의';
      case 'low':
      case 'minor':
        return '미학인';
      default:
        return severity;
    }
  }
}
