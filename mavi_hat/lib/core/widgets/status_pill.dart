import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum StatusPillTone {
  teal,
  navy,
  terracotta,
  danger,
  neutral,
}

/// Compact semantic badge pill used across cards, status headers, and prototype
/// disclaimers.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusPillTone.teal,
    this.showDot = false,
  });

  final String label;
  final IconData? icon;
  final StatusPillTone tone;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    final (Color bg, Color fg) = switch (tone) {
      StatusPillTone.teal => (mavi.secondaryFixed, mavi.onSecondaryFixed),
      StatusPillTone.navy => (mavi.primaryFixed, mavi.onPrimaryFixed),
      StatusPillTone.terracotta => (mavi.tertiaryFixed, mavi.onTertiaryFixed),
      StatusPillTone.danger => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      StatusPillTone.neutral => (
          mavi.surfaceContainerHigh,
          scheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showDot) ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

