import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/mavihat_logo.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../transactions/domain/entities/transit_transaction.dart';
import '../../../transit_card/presentation/widgets/qr_payment_sheet.dart';

/// Screen 8 (`8._home_dashboard`): Main Home Dashboard tab with Hero Digital
/// Transit Card, 4 Quick Actions, Ferry Announcement Banner, Quick Top-Up
/// widget, and Recent Transactions list.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _selectedQuickAmount = 100.0;
  bool _bannerDismissed = false;

  static IconData _iconForStationText(String stationText) {
    final text = stationText.toLowerCase();
    if (text.contains('tramvay') ||
        text.contains('tünel') ||
        text.contains('t1') ||
        text.contains('f2')) {
      return Icons.tram_rounded;
    }
    if (text.contains('iett') ||
        text.contains('otobüs') ||
        text.contains('metrobüs') ||
        text.contains('peron')) {
      return Icons.directions_bus_filled_rounded;
    }
    if (text.contains('metro') || text.contains('marmaray')) {
      return Icons.subway_rounded;
    }
    if (text.contains('iskele') ||
        text.contains('vapur') ||
        text.contains('deniz')) {
      return Icons.directions_boat_filled_rounded;
    }
    return Icons.directions_transit_filled_rounded;
  }

  void _showNotificationsSheet() {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: mavi.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Bildirimler & Duyurular',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: mavi.secondaryFixed,
                  child: Icon(
                    Icons.directions_boat_rounded,
                    color: mavi.onSecondaryFixed,
                  ),
                ),
                title: const Text(
                  'Şehir Hatları Kış Tarifesi Başladı',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Kadıköy - Karaköy - Eminönü hatlarında gece seferleri cuma ve cumartesi devam ediyor.',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go(RouteNames.map);
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: mavi.primaryFixed,
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: mavi.onPrimaryFixed,
                  ),
                ),
                title: const Text(
                  '₺200,00 Bakiye Yükleme Tamamlandı',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'MaviHat •••• 4821 kartınıza TROY kartınızla dolum yapıldı.',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(RouteNames.transactionHistory);
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Bildirim Ayarlarını Yönet',
                variant: AppButtonVariant.tonal,
                height: 46,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(RouteNames.settingsPreferences);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _triggerQuickTopUp() {
    final card = ref.read(transitCardControllerProvider);
    if (card.isUnpaired) {
      context.go(RouteNames.myCard);
      return;
    }
    ref
        .read(topUpDraftControllerProvider.notifier)
        .setAmount(_selectedQuickAmount);
    context.push(RouteNames.confirmTopUp);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserControllerProvider);
    final card = ref.watch(transitCardControllerProvider);
    final transactions = ref.watch(transactionsControllerProvider);
    final recentTxns = transactions.take(4).toList();
    final parts = CurrencyFormatter.splitParts(card.balance);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                onNotificationTap: _showNotificationsSheet,
                onAvatarTap: () => context.go(RouteNames.profile),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    // Greeting & Card Status Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'İSTANBUL ŞEHİR KARTI',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.secondary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${l10n.greetingPrefix}, ${user?.firstName ?? 'Shahd'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: card.isUnpaired
                              ? 'KART EŞLEŞTİRİN'
                              : card.isLocked
                                  ? 'KART KİLİTLİ'
                                  : 'AKTİF KART',
                          tone: card.isUnpaired || card.isLocked
                              ? StatusPillTone.danger
                              : StatusPillTone.teal,
                          showDot: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (card.isUnpaired)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.bosphorusCardGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: <Widget>[
                            const Icon(
                              Icons.add_card_rounded,
                              color: Color(0xFFA9EFED),
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Fiziksel Ulaşım Kartınızı Eşleştirin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Yeni hesabınıza fiziksel İstanbul ulaşım kartınızı tanımlayarak bakiye yüklemeye ve NFC/QR geçiş yapmaya başlayın.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppButton(
                              label: 'Fiziksel Kart Eşleştir',
                              variant: AppButtonVariant.secondary,
                              icon: Icons.credit_card_rounded,
                              height: 46,
                              onPressed: () => context.go(RouteNames.myCard),
                            ),
                          ],
                        ),
                      )
                    else
                    // Hero Istanbul Smart Transit Card
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.go(RouteNames.myCard),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.bosphorusCardGradient,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF8DD3D1).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Row(
                                    children: <Widget>[
                                      const MaviHatLogo(size: 34),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Text(
                                              'İSTANBUL ULAŞIM KARTI',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              card.cardTypeLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFA9EFED),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    card.maskedNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFFF6D365),
                                        Color(0xFFDAA520),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.memory_rounded,
                                    color: Color(0xFF4A3500),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        'MEVCUT BAKİYE',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.72),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: <Widget>[
                                          const Text(
                                            '₺',
                                            style: TextStyle(
                                              color: Color(0xFFA9EFED),
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            parts.whole,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 38,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1.0,
                                            ),
                                          ),
                                          Text(
                                            parts.decimal,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.82),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '6370  34••  ••••  ${card.lastFour}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFA9EFED),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            _iconForStationText(
                                              card.lastStationName,
                                            ),
                                            color: const Color(0xFFA9EFED),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Son Geçiş: ${card.lastStationName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.go(RouteNames.topUp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    l10n.topUpAction,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'Aylık MaviHat Abonman: ${card.subscriptionRemaining} Geçiş Kaldı',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.88),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '15 Kasım’a kadar',
                                    style: TextStyle(
                                      color: Color(0xFFA9EFED),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 4 Primary Quick Actions Grid
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.credit_card_rounded,
                            label: l10n.navCard,
                            onTap: () => context.go(RouteNames.myCard),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.qr_code_2_rounded,
                            label: 'QR ile Öde',
                            badge: '2 DK',
                            onTap: () => showQrPaymentSheet(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.contactless_rounded,
                            label: 'NFC Geçiş',
                            badge: 'AKTİF',
                            onTap: () =>
                                context.push(RouteNames.nfcContactlessInfo),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.map_rounded,
                            label: l10n.navMap,
                            onTap: () => context.go(RouteNames.map),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Şehir Hatları Ferry Campaign Banner
                    if (!_bannerDismissed) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: mavi.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: mavi.tertiaryFixed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_boat_filled_rounded,
                                color: mavi.onTertiaryFixed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const StatusPill(
                                    label: 'ŞEHİR HATLARI HABER & DUYURU',
                                    tone: StatusPillTone.terracotta,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Boğaz Hatlarında %50 Aktarma İndirimi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    'Metro ve Marmaray sonrası şehir içi vapur geçişlerinde %50 aktarma indirimi uygulanmaktadır.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Duyuruyu Kapat',
                              onPressed: () {
                                setState(() => _bannerDismissed = true);
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Quick Top-Up Widget
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  l10n.quickTopUp,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.primary,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Komisyonsuz • Anında',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <double>[50, 100, 200, 500].map((amt) {
                              final selected = _selectedQuickAmount == amt;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: amt == 500 ? 0 : 8,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(
                                        () => _selectedQuickAmount = amt,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? scheme.primary
                                            : mavi.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? scheme.primary
                                              : scheme.outlineVariant
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        '₺${amt.toInt()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: selected
                                              ? Colors.white
                                              : scheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label:
                                '₺${_selectedQuickAmount.toInt()},00 Hızlı Yükle',
                            icon: Icons.bolt_rounded,
                            height: 48,
                            onPressed: _triggerQuickTopUp,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Recent Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.recentTransactions,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push(RouteNames.transactionHistory),
                          icon: const Icon(Icons.list_alt_rounded, size: 18),
                          label: Text(l10n.seeAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final txn in recentTxns)
                      _TransactionRowItem(
                        transaction: txn,
                        onTap: () => context.push(
                          '${RouteNames.transactionDetail}?id=${txn.id}',
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    return Material(
      color: mavi.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mavi.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: scheme.primary, size: 22),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: mavi.tertiaryFixed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: mavi.onTertiaryFixed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRowItem extends StatelessWidget {
  const _TransactionRowItem({
    required this.transaction,
    required this.onTap,
  });

  final TransitTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    final combinedText =
        '${transaction.title} ${transaction.subtitle} ${transaction.lineCode}'
            .toLowerCase();
    final bool isTram = transaction.category == 'tram' ||
        combinedText.contains('tramvay') ||
        combinedText.contains('tünel');
    final bool isFerry = transaction.category == 'ferry' ||
        combinedText.contains('iskele') ||
        combinedText.contains('vapur');
    final bool isBus = transaction.category == 'bus' ||
        combinedText.contains('iett') ||
        combinedText.contains('otobüs') ||
        combinedText.contains('metrobüs');
    final bool isMetro = transaction.category == 'metro' ||
        combinedText.contains('metro') ||
        combinedText.contains('marmaray');

    final (IconData icon, Color bg, Color fg) =
        transaction.category == 'topUp'
            ? (
                Icons.add_card_rounded,
                mavi.secondaryFixed,
                mavi.onSecondaryFixed,
              )
            : isTram
                ? (
                    Icons.tram_rounded,
                    mavi.primaryFixed,
                    mavi.onPrimaryFixed,
                  )
                : isMetro
                    ? (
                        Icons.subway_rounded,
                        mavi.primaryFixed,
                        mavi.onPrimaryFixed,
                      )
                    : isBus
                        ? (
                            Icons.directions_bus_filled_rounded,
                            mavi.tertiaryFixed,
                            mavi.onTertiaryFixed,
                          )
                        : isFerry
                            ? (
                                Icons.directions_boat_filled_rounded,
                                mavi.secondaryFixed,
                                mavi.onSecondaryFixed,
                              )
                            : (
                                Icons.directions_transit_filled_rounded,
                                mavi.primaryFixed,
                                mavi.onPrimaryFixed,
                              );

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        transaction.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transaction.subtitle} • ${transaction.displayTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      CurrencyFormatter.formatTl(
                        transaction.amount,
                        showSign: true,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: transaction.isCredit
                            ? scheme.secondary
                            : scheme.onSurface,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatTl(transaction.balanceAfter),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

