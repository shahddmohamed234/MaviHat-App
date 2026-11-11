import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 22 (`22._kart_kilitleme_onay`): Lock Card Confirmation screen with
/// stolen-card 153 reporting checkbox and immediate state persistence.
class LockCardConfirmScreen extends ConsumerStatefulWidget {
  const LockCardConfirmScreen({super.key});

  @override
  ConsumerState<LockCardConfirmScreen> createState() =>
      _LockCardConfirmScreenState();
}

class _LockCardConfirmScreenState extends ConsumerState<LockCardConfirmScreen> {
  bool _reportStolenTo153 = false;
  bool _isSubmitting = false;

  Future<void> _confirmLock() async {
    setState(() => _isSubmitting = true);
    final res = await ref
        .read(transitCardControllerProvider.notifier)
        .lockCard(reportStolenTo153: _reportStolenTo153);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    res.fold(
      onFailure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _reportStolenTo153
                  ? 'Kartınız kilitlendi ve ALO 153 kayıp/çalıntı ön bildirimi kaydedildi (Prototip).'
                  : 'Kartınız güvenlik amacıyla kilitlendi.',
            ),
          ),
        );
        context.go(RouteNames.myCard);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Kart Kilitleme Onayı',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'GÜVENLİK İŞLEMİ',
                  tone: StatusPillTone.danger,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.gpp_maybe_rounded,
                            size: 46,
                            color: scheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${card.alias} (${card.maskedNumber}) kartını kilitlemek üzeresiniz',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: scheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Korunan Bakiye: ${CurrencyFormatter.formatTl(card.balance)} • Abonman: ${card.subscriptionRemaining} Geçiş',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _BulletInfoRow(
                      icon: Icons.shield_rounded,
                      title: 'Bakiyeniz ve Abonmanınız Korunur',
                      subtitle:
                          'Kartınız kilitlendiğinde mevcut TL bakiyeniz ve kalan abonman haklarınız güvence altına alınır.',
                    ),
                    const _BulletInfoRow(
                      icon: Icons.block_rounded,
                      title: 'Yükleme ve Geçişler Durdurulur',
                      subtitle:
                          'Kilitli karta bakiye yüklenemez ve kart kullanımı geçici olarak devre dışı bırakılır.',
                    ),
                    const _BulletInfoRow(
                      icon: Icons.sms_rounded,
                      title: 'SMS Doğrulama ile Geri Açılabilir',
                      subtitle:
                          'Kartınızı bulduğunuzda Kartım sekmesinden SMS kodu ile kilidi dilediğiniz an kaldırabilirsiniz.',
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _reportStolenTo153,
                          onChanged: (v) {
                            setState(() => _reportStolenTo153 = v ?? false);
                          },
                          title: const Text(
                            'Kartımın çalındığından şüpheleniyorum',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: const Text(
                            'ALO 153 Çözüm Merkezi kayıp/çalıntı ön bildirim kaydı oluşturulsun.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: _reportStolenTo153
                          ? 'Kilitle ve 153’e Bildir'
                          : 'Evet, Kartı Kilitle',
                      variant: AppButtonVariant.danger,
                      icon: Icons.lock_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _confirmLock,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Vazgeç',
                      variant: AppButtonVariant.tonal,
                      onPressed: () => context.pop(),
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

class _BulletInfoRow extends StatelessWidget {
  const _BulletInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mavi.surfaceContainerLow,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
        ],
      ),
    );
  }
}

