import 'package:flutter/material.dart';
import '../../core/theme/neubrut_tokens.dart';
export '../../core/widgets/nb_card.dart';
export '../../core/widgets/nb_button.dart';
export '../../core/widgets/nb_input.dart';
export '../../core/widgets/nb_badge.dart';

// ─────────────────────────────────────────────────────────────────────
//  GlassCard → now an NBCard hybrid (keeps the old API intact)
// ─────────────────────────────────────────────────────────────────────

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  /// gradient param accepted but ignored (no gradients in NB)
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? fillColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    // ignore gradient
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.fillColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    return GestureDetector(
      onTapDown:   interactive ? (_) => setState(() => _pressed = true)  : null,
      onTapUp:     interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? ()  => setState(() => _pressed = false) : null,
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        width:  widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.all(NBSpacing.lg),
        decoration: BoxDecoration(
          color: widget.fillColor ?? NBColors.white,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: _pressed ? NBShadows.pressed : NBShadows.medium,
        ),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  StatChip — label + value + icon in Neubrutalism style
// ─────────────────────────────────────────────────────────────────────

class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NBSpacing.md,
        vertical: NBSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: NBColors.white,
        border: Border.all(color: NBColors.black, width: 2),
        borderRadius: NBRadius.softAll,
        boxShadow: NBShadows.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: NBColors.black, size: 20),
          const SizedBox(height: NBSpacing.xs),
          Text(
            value,
            style: NBText.monoSmall.copyWith(color: NBColors.black),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: NBText.label.copyWith(
              color: const Color(0xFF555555),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  AnimatedPercentageRing — preserved as-is (logic unchanged)
// ─────────────────────────────────────────────────────────────────────

class AnimatedPercentageRing extends StatefulWidget {
  final double percentage;
  final double size;
  final Color color;
  final double strokeWidth;
  final Widget? child;

  const AnimatedPercentageRing({
    super.key,
    required this.percentage,
    this.size = 100,
    this.color = NBColors.primary,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  State<AnimatedPercentageRing> createState() => _AnimatedPercentageRingState();
}

class _AnimatedPercentageRingState extends State<AnimatedPercentageRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedPercentageRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: _animation.value,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final bgPaint = Paint()
      ..color = NBColors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;  // Square caps = NB style
    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final sweepAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────
//  SectionHeader — bold uppercase label
// ─────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NBSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Accent bar + label
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: NBColors.primary,
                margin: const EdgeInsets.only(right: NBSpacing.sm),
              ),
              Text(
                title.toUpperCase(),
                style: NBText.label.copyWith(fontSize: 12, letterSpacing: 1.5),
              ),
            ],
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NBSpacing.md,
                  vertical: NBSpacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.small,
                ),
                child: Text(
                  'View All',
                  style: NBText.label.copyWith(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
