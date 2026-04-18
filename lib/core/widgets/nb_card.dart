import 'package:flutter/material.dart';
import '../theme/neubrut_tokens.dart';

/// NB Card — white background, 2 px black border, hard shadow.
/// Supports tactile press (shadow reduces, card shifts slightly).
class NBCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? fillColor;
  final Color? accentBorderColor;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const NBCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(NBSpacing.lg),
    this.fillColor,
    this.accentBorderColor,
    this.shadows,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<NBCard> createState() => _NBCardState();
}

class _NBCardState extends State<NBCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    final shadows = widget.shadows ?? NBShadows.medium;

    return GestureDetector(
      onTapDown:   interactive ? (_) => setState(() => _pressed = true)  : null,
      onTapUp:     interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? ()  => setState(() => _pressed = false) : null,
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width:  widget.width,
        height: widget.height,
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.fillColor ?? NBColors.white,
          border: Border.all(
            color: widget.accentBorderColor ?? NBColors.black,
            width: 2,
          ),
          borderRadius: widget.borderRadius ?? NBRadius.softAll,
          boxShadow: _pressed ? NBShadows.pressed : shadows,
        ),
        child: widget.child,
      ),
    );
  }
}
