import 'package:flutter/material.dart';

class SettingSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Function(double) onChanged;
  final String Function(double)? formatLabel;
  final Color? iconColor;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFFFF5722)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFFFF5722),
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF5722),
              thumbColor: const Color(0xFFFF5722),
              inactiveTrackColor: const Color(0xFFFF5722).withOpacity(0.3),
              overlayColor: const Color(0xFFFF5722).withOpacity(0.1),
              valueIndicatorColor: const Color(0xFFFF5722),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: formatLabel?.call(value) ?? value.toStringAsFixed(0),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}