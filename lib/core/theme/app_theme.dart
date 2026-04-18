import 'package:flutter/material.dart';
import 'neubrut_tokens.dart';

/// Re-export tokens under the old AppColors name so other
/// files that still reference AppColors keep compiling.
class AppColors {
  // ── Core ─────────────────────────────────────
  static const Color primary     = NBColors.primary;
  static const Color primaryLight = NBColors.primary;
  static const Color primaryDark  = NBColors.primary;
  static const Color accent       = NBColors.blue;
  static const Color accentLight  = NBColors.blue;

  // ── Background / Surface ─────────────────────
  static const Color background   = NBColors.bg;
  static const Color surface      = NBColors.white;
  static const Color surfaceLight = Color(0xFFEDE8DF);
  static const Color cardBg       = NBColors.white;

  // ── Status ────────────────────────────────────
  static const Color safe    = NBColors.green;
  static const Color warning = NBColors.orange;
  static const Color danger  = NBColors.danger;

  // ── Text ──────────────────────────────────────
  static const Color textPrimary   = NBColors.black;
  static const Color textSecondary = Color(0xFF333333);
  static const Color textMuted     = Color(0xFF666666);

  // ── Gradient stubs (used by old screens — return flat colour) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [NBColors.primary, NBColors.primary],
  );
  static const LinearGradient safeGradient = LinearGradient(
    colors: [NBColors.green, NBColors.green],
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [NBColors.orange, NBColors.orange],
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [NBColors.danger, NBColors.danger],
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [NBColors.white, NBColors.white],
  );

  static Color statusColor(double pct) => NBColors.statusColor(pct);
  static LinearGradient statusGradient(double pct) => LinearGradient(
    colors: [statusColor(pct), statusColor(pct)],
  );
}

class AppTheme {
  static ThemeData get darkTheme => lightTheme; // expose as single theme

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: NBColors.bg,
      colorScheme: const ColorScheme.light(
        primary: NBColors.primary,
        secondary: NBColors.blue,
        surface: NBColors.white,
        error: NBColors.danger,
        onPrimary: NBColors.black,
        onSecondary: NBColors.black,
        onSurface: NBColors.black,
        onError: NBColors.white,
      ),

      // Remove all Material elevation shadows
      appBarTheme: const AppBarTheme(
        backgroundColor: NBColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: NBColors.black,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: NBColors.black),
      ),

      cardTheme: CardThemeData(
        color: NBColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: NBColors.black, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NBColors.primary,
          foregroundColor: NBColors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: NBColors.black, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NBColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBRadius.max),
          borderSide: const BorderSide(color: NBColors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBRadius.max),
          borderSide: const BorderSide(color: NBColors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBRadius.max),
          borderSide: const BorderSide(color: NBColors.black, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF888888),
          fontWeight: FontWeight.w500,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: NBColors.black,
        contentTextStyle: TextStyle(
          color: NBColors.white,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(NBRadius.max)),
          side: BorderSide(color: NBColors.black, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NBColors.white,
        selectedItemColor: NBColors.black,
        unselectedItemColor: Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        headlineLarge:  NBText.heading1,
        headlineMedium: NBText.heading2,
        titleLarge:     NBText.heading3,
        titleMedium:    NBText.body,
        bodyLarge:      NBText.body,
        bodyMedium:     NBText.bodySmall,
        labelLarge:     NBText.label,
      ),
    );
  }
}
