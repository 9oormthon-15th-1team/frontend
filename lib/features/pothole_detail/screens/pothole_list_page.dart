import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/pothole_status.dart';
import '../../../core/services/api/pothole_api_service.dart';
import '../../../core/services/logging/app_logger.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../models/pothole_info.dart';
import '../widgets/pothole_detail_bottom_sheet.dart';

/// 포트홀 목록 페이지
class PotholeListPage extends StatefulWidget {
  const PotholeListPage({super.key});

  @override
  State<PotholeListPage> createState() => _PotholeListPageState();
}

class _PotholeListPageState extends State<PotholeListPage> {
  List<PotholeInfo> _potholes = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPotholes();
  }

  /// 포트홀 목록 로드 (mock data)
  Future<void> _loadPotholes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final potholes = await PotholeApiService.getPotholes();
      setState(() {
        _potholes = potholes.map((p) => PotholeInfo(
              id: p.id.toString(),
              title: p.address,
              description: p.description.isNotEmpty
                  ? p.description
                  : p.aiSummary ?? '포트홀이 발견되었습니다.',
              latitude: p.latitude,
              longitude: p.longitude,
              address: p.address,
              createdAt: p.createdAt,
              images: p.images,
              status: p.status,
              firstReportedAt: p.createdAt,
              latestReportedAt: p.createdAt,
              reportCount: 2,
              // FIXME: 서버 응답에 API 필드 추가하면 대응 필요
              complaintId: null,
            )).toList();
        _isLoading = false;
      });

      AppLogger.info('포트홀 목록 로드 완료: ${_potholes.length}개');
    } catch (e) {
      AppLogger.error('포트홀 목록 로드 실패', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 필터별 포트홀 목록
  List<PotholeInfo> get _filteredPotholes {
    if (_selectedFilter == 'all') return _potholes;

    // 워크플로우 상태를 PotholeStatus enum으로 매핑
    switch (_selectedFilter) {
      case 'pending':
        return _potholes.where((p) => p.status == PotholeStatus.verificationRequired).toList();
      case 'in_progress':
        return _potholes.where((p) => p.status == PotholeStatus.caution).toList();
      case 'completed':
        return _potholes.where((p) => p.status == PotholeStatus.danger).toList();
      default:
        return _potholes;
    }
  }

  /// 필터별 포트홀 개수 계산
  int _getFilteredCount(String filterValue) {
    switch (filterValue) {
      case 'pending':
        return _potholes.where((p) => p.status == PotholeStatus.verificationRequired).length;
      case 'in_progress':
        return _potholes.where((p) => p.status == PotholeStatus.caution).length;
      case 'completed':
        return _potholes.where((p) => p.status == PotholeStatus.danger).length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('포트홀 목록'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPotholes,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          _buildFilterTabs(),

          // 목록
          Expanded(
            child: _isLoading ? _buildLoadingView() : _buildPotholeList(),
          ),
        ],
      ),
    );
  }

  /// 필터 탭
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip('all', '전체'),
          const SizedBox(width: 8),
          _buildFilterChip('pending', '접수됨'),
          const SizedBox(width: 8),
          _buildFilterChip('in_progress', '처리중'),
          const SizedBox(width: 8),
          _buildFilterChip('completed', '완료됨'),
        ],
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    final count = value == 'all'
        ? _potholes.length
        : _getFilteredCount(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange.normal : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// 로딩 뷰
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '포트홀 목록을 불러오는 중...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 포트홀 목록
  Widget _buildPotholeList() {
    final filteredPotholes = _filteredPotholes;

    if (filteredPotholes.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadPotholes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPotholes.length,
        itemBuilder: (context, index) {
          final pothole = filteredPotholes[index];
          return _buildPotholeCard(pothole, index);
        },
      ),
    );
  }

  /// 빈 상태 뷰
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '포트홀이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 등록된 포트홀이 없습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 포트홀 카드
  Widget _buildPotholeCard(PotholeInfo pothole, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPotholeDetail(pothole),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (제목 + 상태)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pothole.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pothole.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pothole.statusKorean,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 위치 정보
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pothole.address,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 설명
                Text(
                  pothole.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // 하단 정보 (날짜 + 이미지 개수)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(pothole.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (pothole.images.isNotEmpty) ...[
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pothole.images.length}장',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 날짜 포맷
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  /// 포트홀 상세 정보 표시
  void _showPotholeDetail(PotholeInfo pothole) {
    PotholeDetailBottomSheet.show(context, pothole);
  }
}
