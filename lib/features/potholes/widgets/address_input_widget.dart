import 'package:flutter/material.dart';

class AddressInputWidget extends StatelessWidget {
  final String address;
  final VoidCallback onRefresh;
  final Function(String) onAddressChanged;

  const AddressInputWidget({
    super.key,
    required this.address,
    required this.onRefresh,
    required this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddressDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: address,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('주소 입력'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '주소를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                onAddressChanged(controller.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
