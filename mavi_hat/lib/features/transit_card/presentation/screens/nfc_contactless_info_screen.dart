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
import '../../../transactions/domain/entities/transit_transaction.dart';
import '../../domain/entities/transit_card.dart';
import '../widgets/qr_payment_sheet.dart';

/// Screen 11 (`11._temass_z_kullan_m`): Active NFC Contactless Turnstile Pass
/// & Dynamic QR Payment launch screen with automatic validator detection across
/// the 10-station Istanbul network and sequential tap counting
/// (1. Basım Abonman -> 2., 3., 4., 5. Basım TL).
class NfcContactlessInfoScreen extends ConsumerStatefulWidget {
  const NfcContactlessInfoScreen({super.key});

  @override
  ConsumerState<NfcContactlessInfoScreen> createState() =>
      _NfcContactlessInfoScreenState();
}

class _NfcContactlessInfoScreenState
    extends ConsumerState<NfcContactlessInfoScreen> {
  static const double _standardFullFareTl = 20.00; // Sabit Tam Biniş Tarifesi

  bool _isScanning = false;
  bool _isHowItWorksExpanded = false;
  String? _lastPassSuccessMessage;
  String? _errorMessage;
  late AutoValidatorTerminal _detectedTerminal;

  @override
  void initState() {
    super.initState();
    final currentCard = ref.read(transitCardControllerProvider);
    _detectedTerminal = AutoValidatorTerminal.nextTerminalAfter(
      currentCard.lastStationName,
    );
  }

  /// Counts consecutive fare taps at the currently detected validator terminal
  /// within the last 15 minutes so the next tap is 1. Basım, 2. Basım, 3. Basım, 4. Basım, 5. Basım...
  int _countConsecutiveTapsAtDetectedTerminal(List<TransitTransaction> txns) {
    int count = 0;
    final now = DateTime.now();
    for (final t in txns) {
      if (t.type == TransactionType.fare) {
        if (now.difference(t.timestamp).abs().inMinutes < 15 &&
            t.title == _detectedTerminal.stationName) {
          count++;
        } else {
          break;
        }
      }
    }
    return count;
  }

  void _detectNextTurnstileTerminal() {
    setState(() {
      _detectedTerminal = AutoValidatorTerminal.nextTerminalAfter(
        _detectedTerminal.stationName,
      );
      _errorMessage = null;
      _lastPassSuccessMessage = null;
    });
  }

  Future<void> _performNfcTurnstilePass({
    required int tapNumber,
    required bool willUseSubscription,
  }) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _lastPassSuccessMessage = null;
    });

    final res = await ref
        .read(transitCardControllerProvider.notifier)
        .executeTurnstilePass(
          stationName: _detectedTerminal.stationName,
          lineDescription: _detectedTerminal.lineDescription,
          category: _detectedTerminal.category,
          fareAmount: _standardFullFareTl,
          methodLabel: 'NFC Temassız Geçiş',
          latitude: _detectedTerminal.lat,
          longitude: _detectedTerminal.lng,
          useSubscription: willUseSubscription,
        );

    if (!mounted) return;
    setState(() => _isScanning = false);

    res.fold(
      onFailure: (f) {
        setState(() => _errorMessage = f.message);
      },
      onSuccess: (updatedCard) {
        final msg = willUseSubscription
            ? '1. Basım Başarılı (${_detectedTerminal.stationName}): Aylık abonmandan 1 hak düşüldü (Kalan Abonman: ${updatedCard.subscriptionRemaining}). Aynı turnikede 2., 3., 4., 5. basımlar TL bakiyeden çekilir.'
            : '$tapNumber. Basım Başarılı (${_detectedTerminal.stationName}): TL bakiyeden -${CurrencyFormatter.formatTl(_standardFullFareTl)} çekildi (Kalan Bakiye: ${CurrencyFormatter.formatTl(updatedCard.balance)}).';
        setState(() => _lastPassSuccessMessage = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final txns = ref.watch(transactionsControllerProvider);
    final eligibility = ref.watch(checkNfcEligibilityUseCaseProvider)(card);

    final nextTapNumber = _countConsecutiveTapsAtDetectedTerminal(txns) + 1;
    final willUseSubscription =
        nextTapNumber == 1 && card.subscriptionRemaining > 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'NFC & QR Temassız Geçiş',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: StatusPill(
                  label: eligibility.isCardActive ? 'NFC AKTİF' : 'KART GEREKLİ',
                  tone: eligibility.isCardActive
                      ? StatusPillTone.teal
                      : StatusPillTone.terracotta,
                  showDot: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Active NFC Turnstile Reader Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFA9EFED),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.contactless_rounded,
                              color: Color(0xFFA9EFED),
                              size: 46,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            eligibility.statusTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bindiğiniz durak ve hat, turnike validatör cihazı tarafından otomatik olarak algılanır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                          if (!card.isUnpaired) ...<Widget>[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${card.alias} (${card.maskedNumber}) • Bakiye: ${CurrencyFormatter.formatTl(card.balance)} • Abonman: ${card.subscriptionRemaining} Hak',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_lastPassSuccessMessage != null) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: mavi.secondaryFixed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.check_circle_rounded,
                              color: mavi.onSecondaryFixed,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _lastPassSuccessMessage!,
                                style: TextStyle(
                                  color: mavi.onSecondaryFixed,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_errorMessage != null) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (card.isUnpaired) ...<Widget>[
                      AppButton(
                        label: 'Fiziksel Kart Eşleştirmeye Git',
                        icon: Icons.add_card_rounded,
                        onPressed: () => context.go(RouteNames.myCard),
                      ),
                      const SizedBox(height: 18),
                    ] else if (card.isLocked) ...<Widget>[
                      AppButton(
                        label: 'Kart Kilidini Açmak İçin Kartım’a Git',
                        icon: Icons.lock_open_rounded,
                        onPressed: () => context.go(RouteNames.myCard),
                      ),
                      const SizedBox(height: 18),
                    ] else ...<Widget>[
                      // Automatically Detected Turnstile Machine Badge + Switch Terminal Option
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: mavi.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.secondary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.sensors_rounded,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Algılanan Turnike: ${_detectedTerminal.stationName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_detectedTerminal.lineDescription} • ${_detectedTerminal.validatorCode}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _detectNextTurnstileTerminal,
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Farklı Durak',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: mavi.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              willUseSubscription
                                  ? Icons.confirmation_number_rounded
                                  : Icons.account_balance_wallet_rounded,
                              color: willUseSubscription
                                  ? scheme.secondary
                                  : scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    willUseSubscription
                                        ? 'Sıradaki Geçiş: 1. Basım (Aylık Abonmandan 1 Hak)'
                                        : 'Sıradaki Geçiş: $nextTapNumber. Basım (TL Bakiyeden ${CurrencyFormatter.formatTl(_standardFullFareTl)})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    willUseSubscription
                                        ? 'Validatör cihazı durağı otomatik algılar. 1. basımda abonmandan düşer (${card.subscriptionRemaining} / ${card.subscriptionTotal} hak). Aynı turnikede 2., 3., 4., 5. basımlarda ₺20,00 TL çekilir.'
                                        : 'Aynı turnikede arka arkaya $nextTapNumber. basım yapıldığı için sabit tam biniş ücreti (${CurrencyFormatter.formatTl(_standardFullFareTl)}) TL bakiyeden tahsil edilir.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: willUseSubscription
                            ? 'NFC ile Turnikeden Geç (1. Basım • Abonman)'
                            : 'NFC ile Turnikeden Geç ($nextTapNumber. Basım • ${CurrencyFormatter.formatTl(_standardFullFareTl)})',
                        icon: Icons.contactless_rounded,
                        isLoading: _isScanning,
                        onPressed: () => _performNfcTurnstilePass(
                          tapNumber: nextTapNumber,
                          willUseSubscription: willUseSubscription,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'QR Kod ile Öde (2 Dk Süreli • 30 Sn Değişen)',
                        variant: AppButtonVariant.tonal,
                        icon: Icons.qr_code_2_rounded,
                        onPressed: () => showQrPaymentSheet(context),
                      ),
                      const SizedBox(height: 18),
                    ],
                    // Expandable technical details drawer
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _isHowItWorksExpanded = !_isHowItWorksExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      'Otomatik Turnike Algılama ve Basım Sırası Nasıl Çalışır?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _isHowItWorksExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                  ),
                                ],
                              ),
                              if (_isHowItWorksExpanded) ...<Widget>[
                                const SizedBox(height: 12),
                                const Text(
                                  '• Otomatik İstasyon Algılama: Her yeni QR veya NFC açılışında validatör makinesi güzergah üzerindeki sıradaki durağı otomatik algılar (veya "Farklı Durak" ile başka bir turnikeye geçebilirsiniz).\n'
                                  '• 1., 2., 3., 4., 5. Basım Kuralı: İlk basımda (1. Basım) kartınızda abonman hakkı varsa otomatik olarak abonmandan düşer. Aynı turnikede arka arkaya 2., 3., 4., 5. kez basıldığında ise her basım için sabit ₺20,00 TL bakiyeden düşülür.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Kartıma Dön',
                      variant: AppButtonVariant.outline,
                      icon: Icons.credit_card_rounded,
                      onPressed: () => context.go(RouteNames.myCard),
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
