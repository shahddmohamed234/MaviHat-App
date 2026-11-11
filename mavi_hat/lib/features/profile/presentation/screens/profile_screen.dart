import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 24 (`24._profilim`): Profile hub tab with user summary, masked TCKN
/// and phone badges, quick stats, and navigation to Personal Info (25),
/// Payment Methods (15), Settings (26), Help & FAQ (27), Offline View (31),
/// Logout Confirm (29), and Delete Account Confirm (30).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserControllerProvider);
    final card = ref.watch(transitCardControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider);

    final displayName = user?.displayName ?? 'Shahd Mohamed Kassem';
    final email = user?.email ?? 'shahd.kassem@mavihat.istanbul';
    final maskedPhone = DataMasker.maskPhone(
      user?.phoneNumber ?? '+90 532 418 90 42',
    );
    final maskedTckn = user?.tcknProfileMasked ?? '180******42';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: l10n.navProfile,
                trailing: IconButton(
                  tooltip: 'Profili Düzenle',
                  onPressed: () => context.push(RouteNames.personalInfoSecurity),
                  icon: Icon(Icons.edit_outlined, color: scheme.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Profile Identity Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white54,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  user?.initials ?? 'SK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'TCKN: $maskedTckn',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    maskedPhone,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFA9EFED),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Monthly Transit Stats Strip
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Aylık Yolculuk',
                            value: '${card.subscriptionUsed} Biniş',
                            icon: Icons.directions_boat_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Kalan Abonman',
                            value: '${card.subscriptionRemaining} Hak',
                            icon: Icons.confirmation_number_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'HESAP VE KART YÖNETİMİ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ProfileNavTile(
                      icon: Icons.person_outline_rounded,
                      title: l10n.personalInfoAndSecurity,
                      subtitle: 'Ad soyad, telefon, şifre ve biyometrik giriş',
                      onTap: () => context.push(RouteNames.personalInfoSecurity),
                    ),
                    _ProfileNavTile(
                      icon: Icons.credit_card_rounded,
                      title: 'Ödeme Yöntemlerim',
                      subtitle: 'Kayıtlı TROY / Mastercard ve otomatik dolum',
                      onTap: () => context.push(RouteNames.paymentMethods),
                    ),
                    _ProfileNavTile(
                      icon: Icons.tune_rounded,
                      title: l10n.settingsAndPrefs,
                      subtitle:
                          'Tema (${prefs.themeMode.name.toUpperCase()}), Dil (${prefs.localeCode.toUpperCase()}), Bildirimler',
                      onTap: () => context.push(RouteNames.settingsPreferences),
                    ),
                    _ProfileNavTile(
                      icon: Icons.help_outline_rounded,
                      title: l10n.helpAndFaq,
                      subtitle: 'Sıkça sorulan sorular, rehberler ve ALO 153',
                      onTap: () => context.push(RouteNames.helpAndFaq),
                    ),
                    _ProfileNavTile(
                      icon: Icons.wifi_off_rounded,
                      title: 'Çevrim Dışı Kart Görünümü (Offline Mod)',
                      subtitle: 'Önbellekteki son bakiye ve QR kart durumu',
                      trailing: const StatusPill(
                        label: 'HIVE CE',
                        tone: StatusPillTone.teal,
                      ),
                      onTap: () => context.push(RouteNames.offlineStatus),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OTURUM VE GÜVENLİK İŞLEMLERİ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ProfileNavTile(
                      icon: Icons.logout_rounded,
                      title: l10n.signOut,
                      subtitle: 'Bu cihazdaki MaviHat oturumunu sonlandır',
                      onTap: () => context.push(RouteNames.logoutConfirm),
                    ),
                    _ProfileNavTile(
                      icon: Icons.delete_forever_rounded,
                      title: l10n.deleteAccount,
                      subtitle: 'Hesabınızı ve yerel verilerinizi kalıcı silin',
                      isDestructive: true,
                      onTap: () => context.push(RouteNames.deleteAccountConfirm),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'MaviHat İstanbul Ulaşım Cüzdanı • Sürüm 2.4.1 (Build 108)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mavi.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: scheme.secondary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  const _ProfileNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final fg = isDestructive ? scheme.error : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: mavi.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? scheme.errorContainer
                        : mavi.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: fg, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDestructive ? scheme.error : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  trailing!,
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
