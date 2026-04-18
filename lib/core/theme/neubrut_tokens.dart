import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────
/// LUMINA — Neubrutalism Design Tokens
/// ──────────────────────────────────────────────

class NBColors {
  // ── Core Palette ─────────────────────────────
  static const Color bg      = Color(0xFFF5F0E8);
  static const Color primary = Color(0xFFFFD93D);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color black   = Color(0xFF000000);

  // ── Accent Palette ────────────────────────────
  static const Color pink    = Color(0xFFFF6B9D);
  static const Color blue    = Color(0xFF74B9FF);
  static const Color green   = Color(0xFF77DD77);
  static const Color purple  = Color(0xFFB8A9E8);
  static const Color orange  = Color(0xFFFFAB76);
  static const Color danger  = Color(0xFFFF6B6B);

  // ── Semantic Colors ───────────────────────────
  static const Color safe    = green;
  static const Color warning = orange;

  /// Returns green / orange / red based on attendance / score percentage
  static Color statusColor(double pct) {
    if (pct >= 75) return green;
    if (pct >= 60) return orange;
    return danger;
  }
}

class NBBorders {
  /// Standard 2 px solid black border
  static const Border standard = Border.fromBorderSide(
    BorderSide(color: NBColors.black, width: 2),
  );

  /// Major container 3 px solid black border
  static const Border major = Border.fromBorderSide(
    BorderSide(color: NBColors.black, width: 3),
  );
}

class NBRadius {
  /// Sharp edges – prefer 0
  static const double sharp = 0;

  /// Max allowed radius (4 px)
  static const double max = 4;

  static const BorderRadius sharpAll = BorderRadius.zero;
  static const BorderRadius softAll  = BorderRadius.all(Radius.circular(max));
}

class NBShadows {
  /// Small hard shadow – Offset(2,2)
  static const List<BoxShadow> small = [
    BoxShadow(color: NBColors.black, offset: Offset(2, 2), blurRadius: 0),
  ];

  /// Medium hard shadow – Offset(4,4)
  static const List<BoxShadow> medium = [
    BoxShadow(color: NBColors.black, offset: Offset(4, 4), blurRadius: 0),
  ];

  /// Large hard shadow – Offset(6,6)
  static const List<BoxShadow> large = [
    BoxShadow(color: NBColors.black, offset: Offset(6, 6), blurRadius: 0),
  ];

  /// Pressed state (no shadow / 0 offset)
  static const List<BoxShadow> pressed = [
    BoxShadow(color: NBColors.black, offset: Offset(1, 1), blurRadius: 0),
  ];
}

class NBSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 28;
}

class NBText {
  // Heading – weight 800+
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: NBColors.black,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: NBColors.black,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: NBColors.black,
  );

  // Body – weight 500
  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: NBColors.black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: NBColors.black,
  );

  // Label – uppercase, small, bold
  static const TextStyle label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: NBColors.black,
    letterSpacing: 1.2,
  );

  // Monospace bold for numbers
  static const TextStyle mono = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: NBColors.black,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: NBColors.black,
  );
}
