import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds Material 3 [ThemeData] for Light, Dark, and High-Contrast modes.
abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) {
    final primaryColor =
        highContrast ? const Color(0xFF001424) : AppColors.primary;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant:
          highContrast ? AppColors.onSurface : AppColors.onSurfaceVariant,
      outline: highContrast ? AppColors.onSurface : AppColors.outline,
      outlineVariant:
          highContrast ? AppColors.outline : AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.buildTextTheme(
        AppColors.onSurface,
        highContrast ? AppColors.onSurface : AppColors.onSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        MaviHatThemeExtension.light,
      ],
    );
  }

  static ThemeData dark({bool highContrast = false}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryFixed,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: const Color(0xFF164B4A),
      onSecondaryContainer: AppColors.secondaryFixed,
      tertiary: AppColors.tertiaryFixedDim,
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.tertiaryFixed,
      error: AppColors.darkError,
      onError: const Color(0xFF690005),
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.errorContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: highContrast
          ? AppColors.darkOnSurface
          : AppColors.darkOnSurfaceVariant,
      outline: highContrast ? AppColors.darkOnSurface : AppColors.darkOutline,
      outlineVariant:
          highContrast ? AppColors.darkOutline : AppColors.darkOutlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.buildTextTheme(
        AppColors.darkOnSurface,
        highContrast
            ? AppColors.darkOnSurface
            : AppColors.darkOnSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceContainerHigh,
        contentTextStyle: const TextStyle(
          color: AppColors.darkOnSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        MaviHatThemeExtension.dark,
      ],
    );
  }
}

