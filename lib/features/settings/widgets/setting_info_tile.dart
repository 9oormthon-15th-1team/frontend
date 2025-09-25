import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/theme/tokens/app_typography.dart';

class SettingInfoTile extends StatelessWidget {
  final String? icon;
  final String title;
  final String value;
  final Color? iconColor;
  final TextStyle? titleStyle;

  const SettingInfoTile({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                icon!,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF4A4A4A),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2A2A2A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}