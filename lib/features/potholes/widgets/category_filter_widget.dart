import 'package:flutter/material.dart';
import '../pothole_list_page.dart';

class CategoryFilterWidget extends StatelessWidget {
  final SortType currentSortType;
  final String? selectedSeverityFilter;
  final String? selectedStatusFilter;
  final Function(SortType) onSortChanged;
  final Function(String?) onSeverityFilterChanged;
  final Function(String?) onStatusFilterChanged;

  const CategoryFilterWidget({
    super.key,
    required this.currentSortType,
    required this.selectedSeverityFilter,
    required this.selectedStatusFilter,
    required this.onSortChanged,
    required this.onSeverityFilterChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 정렬 옵션
          Row(
            children: [
              const Text(
                '정렬:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SortType.values.map((sortType) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sortType.displayName),
                          selected: currentSortType == sortType,
                          onSelected: (selected) {
                            if (selected) {
                              onSortChanged(sortType);
                            }
                          },
                          selectedColor: const Color(0xFFFF5722).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFFF5722),
                          labelStyle: TextStyle(
                            color: currentSortType == sortType
                                ? const Color(0xFFFF5722)
                                : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 필터 옵션
          Row(
            children: [
              const Text(
                '필터:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    // 심각도 필터
                    Expanded(
                      child: _buildFilterDropdown(
                        label: '심각도',
                        value: selectedSeverityFilter,
                        items: ['위험', '주의', '미학인'],
                        onChanged: onSeverityFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 상태 필터
                    Expanded(
                      child: _buildFilterDropdown(
                        label: '상태',
                        value: selectedStatusFilter,
                        items: ['신고됨', '처리중', '완료'],
                        onChanged: onStatusFilterChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.grey[600],
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                '전체',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}