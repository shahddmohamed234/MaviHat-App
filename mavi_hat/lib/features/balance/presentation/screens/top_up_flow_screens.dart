import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 17 (`17._y_klemeyi_onayla`): Top-Up Confirmation Receipt screen with
/// sandbox failure simulation toggle so both success (19) and failure (20)
/// flows can be tested end-to-end.
class ConfirmTopUpScreen extends ConsumerWidget {
  const ConfirmTopUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final draft = ref.watch(topUpDraftControllerProvider);
    final methods = ref.watch(paymentMethodsControllerProvider);
    final method = methods
            .where((m) => m.id == draft.paymentMethodId)
            .firstOrNull ??
        (methods.isNotEmpty ? methods.first : null);

    final projected = card.balance + draft.amount;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Yüklemeyi Onayla',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'SANDBOX ÖDEME',
                  tone: StatusPillTone.terracotta,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'ÖDENECEK TOPLAM TUTAR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.formatTl(draft.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sipariş No: ${draft.orderReference}',
                            style: const TextStyle(
                              color: Color(0xFFA9EFED),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          _SummaryRow(
                            label: 'Yüklenecek Kart',
                            value: '${card.alias} (${card.maskedNumber})',
                          ),
                          const Divider(height: 20),
                          if (draft.isSubscription) ...<Widget>[
                            _SummaryRow(
                              label: 'Abonman Paketi',
                              value:
                                  '${draft.subscriptionTitle} (${draft.subscriptionPasses} Hak)',
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Mevcut Abonman Hakkı',
                              value: '${card.subscriptionRemaining} Geçiş',
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Yükleme Sonrası Abonman',
                              value: '${draft.subscriptionPasses} Geçiş (30 Gün)',
                            ),
                          ] else ...<Widget>[
                            _SummaryRow(
                              label: 'Mevcut Bakiye',
                              value: CurrencyFormatter.formatTl(card.balance),
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Yükleme Sonrası Bakiye',
                              value: CurrencyFormatter.formatTl(projected),
                            ),
                          ],
                          const Divider(height: 20),
                          _SummaryRow(
                            label: 'Ödeme Aracı',
                            value: method?.maskedDisplay ?? 'TROY •••• 4821',
                          ),
                          const Divider(height: 20),
                          const _SummaryRow(
                            label: 'İşlem Ücreti',
                            value: '₺0,00 (Ücretsiz)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Ödemeyi Onayla (3D Secure)',
                      icon: Icons.security_rounded,
                      onPressed: () => context.push(RouteNames.paymentOtp),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Vazgeç ve Geri Dön',
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

/// Screen 18 (`18._demeni_do_rula`): 3D Secure Payment OTP Verification screen.
class PaymentOtpScreen extends ConsumerStatefulWidget {
  const PaymentOtpScreen({super.key});

  @override
  ConsumerState<PaymentOtpScreen> createState() => _PaymentOtpScreenState();
}

class _PaymentOtpScreenState extends ConsumerState<PaymentOtpScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _inlineError;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _completePayment() async {
    setState(() {
      _isProcessing = true;
      _inlineError = null;
    });

    final res = await ref
        .read(topUpDraftControllerProvider.notifier)
        .executePayment(otpCode: _otpCtrl.text);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    res.fold(
      onFailure: (failure) {
        if (failure.code == 'ERR-VAL') {
          setState(() => _inlineError = failure.message);
        } else {
          context.go(RouteNames.topUpFailure);
        }
      },
      onSuccess: (_) {
        context.go(RouteNames.topUpSuccess);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final draft = ref.watch(topUpDraftControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Ödemeni Doğrula (3D Secure)',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'TEST KODU: 123456',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Banka 3D Secure Güvenlik Adımı',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${CurrencyFormatter.formatTl(draft.amount)} tutarındaki MaviHat bakiye yükleme işlemini tamamlamak için telefonunuza gönderilen 6 haneli şifreyi girin.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: '6 Haneli 3D Secure Doğrulama Kodu',
                      hintText: '6 haneli doğrulama kodunu girin',
                      controller: _otpCtrl,
                      errorText: _inlineError,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.lock_clock_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _otpCtrl.clear();
                                _inlineError = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Yeni 3D Secure kodu gönderildi (Örnek Kod: 123456).',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(
                              'Kodu Tekrar Gönder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Ödemeyi Tamamla',
                      icon: Icons.verified_user_rounded,
                      isLoading: _isProcessing,
                      onPressed: _completePayment,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'İşlemi İptal Et',
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

/// Screen 19 (`19._y_kleme_tamamland`): Top-Up Success screen showing the
/// atomically updated balance and newly created transaction reference.
class TopUpSuccessScreen extends ConsumerWidget {
  const TopUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final draft = ref.watch(topUpDraftControllerProvider);
    final res = draft.lastResult;

    final refCode = res?.referenceCode ?? 'TXN-20261024-88310';
    final added = res?.addedAmount ?? draft.amount;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: mavi.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 46,
                  color: mavi.onSecondaryFixed,
                ),
              ),
              const SizedBox(height: 20),
              const StatusPill(
                label: 'SANDBOX DOLUM TAMAMLANDI',
                tone: StatusPillTone.teal,
              ),
              const SizedBox(height: 12),
              Text(
                draft.isSubscription
                    ? 'Abonman ve Bakiye Yükleme Başarılı!'
                    : 'Bakiye Yükleme Başarılı!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                draft.isSubscription
                    ? '${draft.subscriptionTitle} (+${draft.subscriptionPasses} Geçiş Hakkı) ${card.alias} (${card.maskedNumber}) kartınıza anında tanımlandı.'
                    : '${CurrencyFormatter.formatTl(added)} tutarındaki dolum ${card.alias} (${card.maskedNumber}) kartınıza anında tanımlandı.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.bosphorusCardGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      draft.isSubscription
                          ? 'GÜNCEL ABONMAN HAKKI & KART BAKİYESİ'
                          : 'GÜNCEL KART BAKİYESİ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.isSubscription
                          ? '${card.subscriptionRemaining} Geçiş (${CurrencyFormatter.formatTl(card.balance)})'
                          : CurrencyFormatter.formatTl(card.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: refCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Referans kodu kopyalandı: $refCode'),
                          ),
                        );
                      },
                      child: Text(
                        'İşlem Referansı: $refCode (Kopyala)',
                        style: const TextStyle(
                          color: Color(0xFFA9EFED),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Ana Sayfaya Dön',
                icon: Icons.home_rounded,
                onPressed: () => context.go(RouteNames.home),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'İşlem Detayını / Makbuzu Gör',
                variant: AppButtonVariant.tonal,
                icon: Icons.receipt_long_rounded,
                onPressed: () => context.push(
                  '${RouteNames.transactionDetail}?id=${res?.transactionId ?? refCode}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 20 (`20._deme_tamamlanamad`): Top-Up Failure screen (`ERR-4012`)
/// confirming that card balance was not altered.
class TopUpFailureScreen extends ConsumerWidget {
  const TopUpFailureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final draft = ref.watch(topUpDraftControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 46,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 18),
              StatusPill(
                label: 'HATA KODU: ${draft.lastErrorCode}',
                tone: StatusPillTone.danger,
              ),
              const SizedBox(height: 12),
              Text(
                'Ödeme Tamamlanamadı',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                draft.lastErrorMessage ??
                    'Bankanız 3D Secure doğrulamasını onaylamadı. Kartınızdan hiçbir tutar çekilmedi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mavi.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'KORUNAN MEVCUT BAKİYENİZ (DEĞİŞMEDİ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatTl(card.balance),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Tekrar Dene',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  ref
                      .read(topUpDraftControllerProvider.notifier)
                      .setSimulateFailure(false);
                  context.go(RouteNames.topUp);
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Ödeme Yöntemini Değiştir',
                variant: AppButtonVariant.tonal,
                icon: Icons.credit_card_rounded,
                onPressed: () => context.push(RouteNames.paymentMethods),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Yardım ve Destek Al',
                variant: AppButtonVariant.ghost,
                icon: Icons.support_agent_rounded,
                onPressed: () => context.push(RouteNames.helpAndFaq),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

