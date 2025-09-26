import 'package:flutter/material.dart';

class AddressInputWidget extends StatefulWidget {
  final String address;
  final VoidCallback onRefresh;
  final Function(String) onAddressChanged;
  final bool isLoading;
  final String? error;

  const AddressInputWidget({
    super.key,
    required this.address,
    required this.onRefresh,
    required this.onAddressChanged,
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
            onTap: () => _showLocationPicker(context),
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

  void _showLocationPicker(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: widget.address,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '위치 설정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '주소를 입력하세요',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    filled: true, // 배경 채우기 활성화
                    fillColor: Colors.white, // 배경 색상 흰색

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B35),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white, // 배경 하얀색
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAddressChanged(controller.text);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
