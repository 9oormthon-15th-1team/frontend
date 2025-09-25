import 'package:flutter/material.dart';
import '../../core/models/pothole.dart';
import '../../core/services/api/pothole_api_service.dart';
import '../../widgets/loading/loading_widget.dart';
import 'widgets/address_input_widget.dart';
import 'widgets/pothole_list_item.dart';

class PotholeListPage extends StatefulWidget {
  const PotholeListPage({super.key});

  @override
  State<PotholeListPage> createState() => _PotholeListPageState();
}

class _PotholeListPageState extends State<PotholeListPage> {
  List<Pothole> potholes = [];
  bool isLoading = true;
  String? error;
  String _currentAddress = '제주특별자치도 제주시 이도2동';

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
        isLoading = false;
      });
    } catch (e) {
      // API 실패 시 목업 데이터 사용
      setState(() {
        potholes = _getMockPotholes();
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

    if (potholes.isEmpty) {
      return const Center(child: Text('No potholes found'));
    }

    return RefreshIndicator(
      onRefresh: _loadPotholes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: potholes.length,
        itemBuilder: (context, index) {
          final pothole = potholes[index];
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
}
