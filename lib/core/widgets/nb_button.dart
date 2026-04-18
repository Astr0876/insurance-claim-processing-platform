import 'package:flutter/material.dart';
import '../theme/neubrut_tokens.dart';

/// NBButton — hard border, hard shadow, tactile press.
class NBButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color fillColor;
  final Color labelColor;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  const NBButton({
    super.key,
    required this.label,
    this.onTap,
    this.fillColor = NBColors.primary,
    this.labelColor = NBColors.black,
    this.icon,
    this.fullWidth = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.textStyle,
  });

  /// Danger-style variant
  const NBButton.danger({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.fullWidth = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.textStyle,
  })  : fillColor = NBColors.danger,
        labelColor = NBColors.white;

  @override
  State<NBButton> createState() => _NBButtonState();
}

class _NBButtonState extends State<NBButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.labelColor, size: 20),
          const SizedBox(width: NBSpacing.sm),
        ],
        Text(
          widget.label.toUpperCase(),
          style: (widget.textStyle ?? NBText.label).copyWith(
            fontSize: 13,
            letterSpacing: 1,
            color: widget.labelColor,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown:   widget.onTap != null ? (_) => setState(() => _pressed = true)  : null,
      onTapUp:     widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? ()  => setState(() => _pressed = false) : null,
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: widget.fillColor,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: _pressed ? NBShadows.pressed : NBShadows.small,
        ),
        child: content,
      ),
    );
  }
}
