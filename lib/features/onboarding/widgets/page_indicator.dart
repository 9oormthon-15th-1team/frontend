import 'package:flutter/material.dart';
import 'package:porthole_in_jeju/core/theme/design_system.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: currentPage == index
                ? AppColors.orange.normal
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}
