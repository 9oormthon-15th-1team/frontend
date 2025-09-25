import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/theme/tokens/app_typography.dart';

class SettingAccordionTile extends StatefulWidget {
  final String? icon;
  final String title;
  final String content;
  final Color? iconColor;
  final TextStyle? titleStyle;

  const SettingAccordionTile({
    super.key,
    this.icon,
    required this.title,
    required this.content,
    this.iconColor,
    this.titleStyle,
  });

  @override
  State<SettingAccordionTile> createState() => _SettingAccordionTileState();
}

class _SettingAccordionTileState extends State<SettingAccordionTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      widget.icon!,
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
                    widget.title,
                    style: widget.titleStyle ?? const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2A2A2A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF8E8E8E),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E8E),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}