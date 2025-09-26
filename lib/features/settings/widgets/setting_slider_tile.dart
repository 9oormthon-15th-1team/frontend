import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingSliderTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Function(double) onChanged;
  final String Function(double)? formatLabel;
  final Color? iconColor;
  final TextStyle? titleStyle;

  const SettingSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.formatLabel,
    this.iconColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, ${formatLabel?.call(value) ?? value.toStringAsFixed(0)}',
      hint: subtitle,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    icon,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4A4A4A),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                  formatLabel?.call(value) ?? '${value.toInt()}m',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF6B35),
                thumbColor: const Color(0xFFFF6B35),
                inactiveTrackColor: const Color(0xFFE0E0E0),
                overlayColor: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                valueIndicatorColor: const Color(0xFFFF6B35),
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}