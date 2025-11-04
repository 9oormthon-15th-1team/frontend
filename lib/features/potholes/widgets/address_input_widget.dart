import 'package:flutter/material.dart';

class AddressInputWidget extends StatefulWidget {
  final String address;
  final VoidCallback onRefresh;
  final bool isLoading;
  final String? error;

  const AddressInputWidget({
    super.key,
    required this.address,
    required this.onRefresh,
    this.isLoading = false,
    this.error,
  });

  @override
  State<AddressInputWidget> createState() => _AddressInputWidgetState();
}

class _AddressInputWidgetState extends State<AddressInputWidget> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + 8,
        left: 0,
        right: 0,
        bottom: 8,
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Semantics(
          label: '현재 위치: ${widget.address}',
          hint: '탭하여 위치 변경',
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            child: Row(
              children: [
                // 좌측 여백
                const SizedBox(width: 20),

                // 위치 아이콘
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 아이콘과 텍스트 간격
                const SizedBox(width: 12),

                // 위치 텍스트
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildLocationText(),
                  ),
                ),

                // 우측 여백
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationText() {
    if (widget.isLoading) {
      return Text(
        '위치를 가져오는 중...',
        key: const ValueKey('loading'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9E9E9E),
          fontStyle: FontStyle.italic,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    if (widget.error != null) {
      return Row(
        key: const ValueKey('error'),
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '위치를 가져올 수 없습니다',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE53E3E),
                letterSpacing: -0.3,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.address,
      key: ValueKey('address_${widget.address}'),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2A2A2A),
        letterSpacing: -0.3,
        height: 1.2,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
