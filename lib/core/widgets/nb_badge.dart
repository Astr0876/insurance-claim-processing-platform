import 'package:flutter/material.dart';
import '../theme/neubrut_tokens.dart';

/// NBBadge — solid colour, 2 px black border, hard drop shadow.
/// Used for status indicators, counts, and labels.
class NBBadge extends StatelessWidget {
  final String label;
  final Color fillColor;
  final Color textColor;
  final double fontSize;

  const NBBadge({
    super.key,
    required this.label,
    this.fillColor = NBColors.primary,
    this.textColor = NBColors.black,
    this.fontSize = 10,
  });

  /// Safe (green) variant
  const NBBadge.safe({
    super.key,
    required this.label,
    this.textColor = NBColors.black,
    this.fontSize = 10,
  }) : fillColor = NBColors.green;

  /// Warning (orange) variant
  const NBBadge.warning({
    super.key,
    required this.label,
    this.textColor = NBColors.black,
    this.fontSize = 10,
  }) : fillColor = NBColors.orange;

  /// Danger (red) variant
  const NBBadge.danger({
    super.key,
    required this.label,
    this.textColor = NBColors.white,
    this.fontSize = 10,
  }) : fillColor = NBColors.danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fillColor,
        border: const Border.fromBorderSide(
          BorderSide(color: NBColors.black, width: 2),
        ),
        borderRadius: NBRadius.softAll,
        boxShadow: NBShadows.small,
      ),
      child: Text(
        label.toUpperCase(),
        style: NBText.label.copyWith(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
