import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      // 실제 구현에서는 API에서 데이터를 가져옴
      await Future.delayed(const Duration(seconds: 1));

      final mockPotholes = _generateMockData();
      setState(() {
        _potholes = mockPotholes;
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

  /// 목업 데이터 생성
  List<PotholeInfo> _generateMockData() {
    final baseImages = [
      'assets/images/danger.png',
      'assets/images/general.png',
      'assets/images/waring.png',
    ];

    // 다양한 상태와 심각도로 더 현실적인 데이터 생성
    final mockDataConfig = [
      // 높은 심각도 (high) - 빨간색
      {'status': 'pending', 'severity': 'high', 'description': '심각한 포트홀 - 차량 파손 위험', 'images': 3},
      {'status': 'in_progress', 'severity': 'high', 'description': '대형 포트홀, 응급 보수 작업 진행중', 'images': 2},
      {'status': 'pending', 'severity': 'high', 'description': '깊은 포트홀로 인한 교통사고 위험', 'images': 3},

      // 중간 심각도 (medium) - 주황색
      {'status': 'pending', 'severity': 'medium', 'description': '중간 크기 포트홀, 보수 작업 필요', 'images': 2},
      {'status': 'in_progress', 'severity': 'medium', 'description': '도로면 손상, 보수 작업 예정', 'images': 1},
      {'status': 'completed', 'severity': 'medium', 'description': '아스팔트 균열 확대로 인한 포트홀', 'images': 2},
      {'status': 'pending', 'severity': 'medium', 'description': '차선 경계 부근 포트홀', 'images': 1},
      {'status': 'in_progress', 'severity': 'medium', 'description': '우천시 물고임 발생 지역', 'images': 3},

      // 낮은 심각도 (low) - 노란색
      {'status': 'pending', 'severity': 'low', 'description': '작은 포트홀, 예방 차원의 보수', 'images': 1},
      {'status': 'completed', 'severity': 'low', 'description': '표면 거칠음 개선 완료', 'images': 1},
      {'status': 'pending', 'severity': 'low', 'description': '경미한 도로 표면 손상', 'images': 2},
      {'status': 'completed', 'severity': 'low', 'description': '인도 접경 부위 작은 균열', 'images': 1},
      {'status': 'pending', 'severity': 'low', 'description': '노면 표시선 근처 손상', 'images': 1},

      // 완료된 케이스들
      {'status': 'completed', 'severity': 'high', 'description': '긴급 보수 작업 완료', 'images': 2},
      {'status': 'completed', 'severity': 'medium', 'description': '정기 도로 보수 작업 완료', 'images': 1},
    ];

    return List.generate(mockDataConfig.length, (index) {
      final config = mockDataConfig[index];
      final dayOffset = index + 1;

      return PotholeInfo(
        id: 'pothole_${index + 1}',
        title: '포트홀 신고 #${(index + 1).toString().padLeft(3, '0')}',
        description: config['description'] as String,
        latitude: 33.5142 + (index * 0.0008), // 더 넓게 분산
        longitude: 126.5292 + (index * 0.0012),
        address: '제주특별시도 제주시 ${[
          '이도일동', '이도이동', '일도일동', '일도이동',
          '연동', '노형동', '외도일동', '외도이동'
        ][index % 8]} ${(100 + index * 3)}${index % 2 == 0 ? '' : '-${(index % 5) + 1}'}번지',
        createdAt: DateTime.now().subtract(
          Duration(days: dayOffset, hours: (index * 3) % 24),
        ),
        images: baseImages.take(config['images'] as int).toList(),
        status: config['status'] as String,
        severity: config['severity'] as String,
        firstReportedAt: DateTime.now().subtract(
          Duration(days: dayOffset + (index % 3) + 1, hours: (index + 8) % 24),
        ),
        latestReportedAt: DateTime.now().subtract(
          Duration(days: dayOffset, hours: (index + 2) % 24),
        ),
        reportCount: (index % 5) + 1, // 1-5번의 신고
        complaintId: config['status'] == 'completed'
          ? 'COMP-2024-${(1200 + index).toString()}'
          : config['severity'] == 'high'
            ? 'URGENT-2024-${(1200 + index).toString()}'
            : '2024-${(1200 + index).toString()}',
      );
    });
  }

  /// 필터별 포트홀 목록
  List<PotholeInfo> get _filteredPotholes {
    if (_selectedFilter == 'all') return _potholes;
    return _potholes.where((p) => p.status == _selectedFilter).toList();
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
        : _potholes.where((p) => p.status == value).length;

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
                        color: Color(
                          int.parse(
                            pothole.statusColor.replaceFirst('#', '0xff'),
                          ),
                        ),
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
