import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../app/theme/app_colors.dart';
import '../localization/app_localizations.dart';
import 'mavihat_logo.dart';

/// Top application header matching the Stitch Bosphorus Civic Transit layout.
class MaviHatHeader extends ConsumerWidget {
  const MaviHatHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.onNotificationTap,
    this.onAvatarTap,
    this.trailing,
    this.unreadNotificationCount = 2,
  });

  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final Widget? trailing;
  final int unreadNotificationCount;

  String _computeInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'MH';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserControllerProvider);
    final initials = _computeInitials(user?.displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: <Widget>[
          if (showBackButton) ...<Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: mavi.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...<Widget>[
            const MaviHatLogo(size: 40),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: title != null
                ? Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'MaviHat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: scheme.primary,
                            ),
                      ),
                      Text(
                        l10n.brandSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: scheme.secondary,
                            ),
                      ),
                    ],
                  ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            Flexible(child: trailing!),
          ] else ...<Widget>[
            if (onNotificationTap != null)
              IconButton(
                tooltip: 'Bildirimler',
                onPressed: onNotificationTap,
                style: IconButton.styleFrom(
                  backgroundColor: mavi.surfaceContainerLow,
                ),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(
                      Icons.notifications_none_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (onAvatarTap != null) ...<Widget>[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onAvatarTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.bosphorusCardGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
