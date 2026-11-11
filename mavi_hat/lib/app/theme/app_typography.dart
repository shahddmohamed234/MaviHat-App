import 'package:flutter/material.dart';

/// Typography tokens pairing Manrope display/headlines with Inter body/labels
/// and tabular numerals for Turkish Lira balances and timestamps.
abstract final class AppTypography {
  static const String displayFontFamily = 'Manrope';
  static const String bodyFontFamily = 'Inter';

  static TextTheme buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.15,
        color: onSurface,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      displayMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.2,
        color: onSurface,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: onSurfaceVariant,
      ),
    );
  }
}

