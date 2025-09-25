import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // 예시 갤러리 데이터
  final List<GalleryItem> _galleryItems = [
    GalleryItem(
      id: '1',
      title: '포트홀 신고 #001',
      location: '제주시 이도2동',
      imageUrl: 'https://via.placeholder.com/300x200/FF6B35/FFFFFF?text=Pothole+1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: PotholeStatus.reported,
    ),
    GalleryItem(
      id: '2',
      title: '포트홀 신고 #002',
      location: '제주시 연동',
      imageUrl: 'https://via.placeholder.com/300x200/F7931E/FFFFFF?text=Pothole+2',
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: PotholeStatus.inProgress,
    ),
    GalleryItem(
      id: '3',
      title: '포트홀 신고 #003',
      location: '제주시 노형동',
      imageUrl: 'https://via.placeholder.com/300x200/FFD23F/FFFFFF?text=Pothole+3',
      date: DateTime.now().subtract(const Duration(days: 7)),
      status: PotholeStatus.completed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '포트홀 갤러리',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: Colors.orange),
            onPressed: _addNewPhoto,
            tooltip: '새 사진 추가',
          ),
        ],
      ),
      body: _galleryItems.isEmpty ? _buildEmptyState() : _buildGalleryGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPhoto,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 신고된 포트홀이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 포트홀을 신고해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewPhoto,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('포트홀 신고하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _galleryItems.length,
        itemBuilder: (context, index) {
          return _buildGalleryCard(_galleryItems[index]);
        },
      ),
    );
  }

  Widget _buildGalleryCard(GalleryItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 정보 영역
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(item.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      _buildStatusChip(item.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(PotholeStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case PotholeStatus.reported:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = '신고됨';
        break;
      case PotholeStatus.inProgress:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = '처리중';
        break;
      case PotholeStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = '완료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

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

  void _addNewPhoto() {
    // 카메라/갤러리에서 사진 선택 기능 (추후 구현)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사진 추가 기능은 추후 구현 예정입니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// 갤러리 아이템 모델
class GalleryItem {
  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final DateTime date;
  final PotholeStatus status;

  GalleryItem({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.date,
    required this.status,
  });
}

// 포트홀 상태 열거형
enum PotholeStatus {
  reported,   // 신고됨
  inProgress, // 처리중
  completed,  // 완료
}