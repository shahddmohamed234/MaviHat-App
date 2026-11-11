import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  tonal,
  outline,
  danger,
  ghost,
}

/// Standardized MaviHat interactive button with loading state protection
/// to prevent duplicate submissions.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 54.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    final (Color bg, Color fg, BorderSide border) = switch (variant) {
      AppButtonVariant.primary => (
          scheme.primary,
          scheme.onPrimary,
          BorderSide.none,
        ),
      AppButtonVariant.secondary => (
          scheme.secondary,
          scheme.onSecondary,
          BorderSide.none,
        ),
      AppButtonVariant.tonal => (
          mavi.surfaceContainerLow,
          scheme.onSurface,
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      AppButtonVariant.outline => (
          Colors.transparent,
          scheme.primary,
          BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      AppButtonVariant.danger => (
          scheme.error,
          scheme.onError,
          BorderSide.none,
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          scheme.onSurfaceVariant,
          BorderSide.none,
        ),
    };

    final buttonChild = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fg,
                  ),
                ),
              ),
              if (trailingIcon != null) ...<Widget>[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 18, color: fg),
              ],
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.65),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: border,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

