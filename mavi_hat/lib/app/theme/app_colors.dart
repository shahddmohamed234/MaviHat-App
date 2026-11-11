import 'package:flutter/material.dart';

/// Semantic color tokens from `lib/design.md` and the Stitch Bosphorus Civic
/// Transit design system.
abstract final class AppColors {
  // Light Palette
  static const Color primary = Color(0xFF00253D);
  static const Color primaryContainer = Color(0xFF183B56);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF83A4C4);
  static const Color primaryFixed = Color(0xFFCDE5FF);
  static const Color primaryFixedDim = Color(0xFFA9CAEB);
  static const Color onPrimaryFixed = Color(0xFF001D32);
  static const Color onPrimaryFixedVariant = Color(0xFF284863);

  static const Color secondary = Color(0xFF1C6968);
  static const Color secondaryContainer = Color(0xFFA6ECEA);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF226D6C);
  static const Color secondaryFixed = Color(0xFFA9EFED);
  static const Color secondaryFixedDim = Color(0xFF8DD3D1);
  static const Color onSecondaryFixed = Color(0xFF002020);

  static const Color tertiary = Color(0xFF490C00);
  static const Color tertiaryContainer = Color(0xFF662210);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFEA876E);
  static const Color tertiaryFixed = Color(0xFFFFDBD2);
  static const Color tertiaryFixedDim = Color(0xFFFFB4A1);
  static const Color onTertiaryFixed = Color(0xFF3C0800);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFFBF9F4);
  static const Color surface = Color(0xFFFBF9F4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3EE);
  static const Color surfaceContainer = Color(0xFFF0EEE9);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E3);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DD);
  static const Color onSurface = Color(0xFF1B1C19);
  static const Color onSurfaceVariant = Color(0xFF42474D);
  static const Color outline = Color(0xFF73777E);
  static const Color outlineVariant = Color(0xFFC2C7CE);

  // Dark Palette
  static const Color darkBackground = Color(0xFF101C25);
  static const Color darkSurface = Color(0xFF14232D);
  static const Color darkSurfaceContainerLowest = Color(0xFF172832);
  static const Color darkSurfaceContainerLow = Color(0xFF1B303A);
  static const Color darkSurfaceContainer = Color(0xFF203741);
  static const Color darkSurfaceContainerHigh = Color(0xFF29434C);
  static const Color darkSurfaceContainerHighest = Color(0xFF324F59);
  static const Color darkOnSurface = Color(0xFFF1F3EF);
  static const Color darkOnSurfaceVariant = Color(0xFFB9C7C8);
  static const Color darkPrimary = Color(0xFFA9CAEB);
  static const Color darkOnPrimary = Color(0xFF102638);
  static const Color darkSecondary = Color(0xFF8DD3D1);
  static const Color darkOnSecondary = Color(0xFF082B2A);
  static const Color darkOutline = Color(0xFF82969A);
  static const Color darkOutlineVariant = Color(0xFF40565D);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkErrorContainer = Color(0xFF93000A);

  // Card Signature Gradient
  static const LinearGradient bosphorusCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF183B56),
      Color(0xFF1F4B6B),
      Color(0xFF2F7776),
    ],
  );

  static const LinearGradient studentCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF1C6968),
      Color(0xFF183B56),
      Color(0xFF00253D),
    ],
  );
}

/// Custom semantic surface extension so widgets never hardcode hex colors.
@immutable
class MaviHatThemeExtension extends ThemeExtension<MaviHatThemeExtension> {
  const MaviHatThemeExtension({
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.cardGradient,
  });

  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Gradient cardGradient;

  static const MaviHatThemeExtension light = MaviHatThemeExtension(
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    secondaryFixed: AppColors.secondaryFixed,
    onSecondaryFixed: AppColors.onSecondaryFixed,
    tertiaryFixed: AppColors.tertiaryFixed,
    onTertiaryFixed: AppColors.onTertiaryFixed,
    primaryFixed: AppColors.primaryFixed,
    onPrimaryFixed: AppColors.onPrimaryFixed,
    cardGradient: AppColors.bosphorusCardGradient,
  );

  static const MaviHatThemeExtension dark = MaviHatThemeExtension(
    surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
    surfaceContainerLow: AppColors.darkSurfaceContainerLow,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    secondaryFixed: Color(0xFF164B4A),
    onSecondaryFixed: Color(0xFFA9EFED),
    tertiaryFixed: Color(0xFF5A2010),
    onTertiaryFixed: Color(0xFFFFDBD2),
    primaryFixed: Color(0xFF1D3E58),
    onPrimaryFixed: Color(0xFFCDE5FF),
    cardGradient: AppColors.bosphorusCardGradient,
  );

  @override
  MaviHatThemeExtension copyWith({
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? secondaryFixed,
    Color? onSecondaryFixed,
    Color? tertiaryFixed,
    Color? onTertiaryFixed,
    Color? primaryFixed,
    Color? onPrimaryFixed,
    Gradient? cardGradient,
  }) {
    return MaviHatThemeExtension(
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  MaviHatThemeExtension lerp(
    covariant ThemeExtension<MaviHatThemeExtension>? other,
    double t,
  ) {
    if (other is! MaviHatThemeExtension) return this;
    return MaviHatThemeExtension(
      surfaceContainerLowest: Color.lerp(
        surfaceContainerLowest,
        other.surfaceContainerLowest,
        t,
      )!,
      surfaceContainerLow: Color.lerp(
        surfaceContainerLow,
        other.surfaceContainerLow,
        t,
      )!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      surfaceContainerHighest: Color.lerp(
        surfaceContainerHighest,
        other.surfaceContainerHighest,
        t,
      )!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      onSecondaryFixed: Color.lerp(
        onSecondaryFixed,
        other.onSecondaryFixed,
        t,
      )!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      onTertiaryFixed: Color.lerp(onTertiaryFixed, other.onTertiaryFixed, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t) ??
          cardGradient,
    );
  }
}

extension MaviHatThemeContext on BuildContext {
  MaviHatThemeExtension get maviTheme =>
      Theme.of(this).extension<MaviHatThemeExtension>() ??
      MaviHatThemeExtension.light;
}

