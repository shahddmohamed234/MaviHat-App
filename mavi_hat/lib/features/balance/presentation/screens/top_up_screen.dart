import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../transit_card/domain/entities/transit_card.dart';

class _SubscriptionPackageOption {
  const _SubscriptionPackageOption({
    required this.title,
    required this.subtitle,
    required this.addedPasses,
    required this.price,
  });

  final String title;
  final String subtitle;
  final int addedPasses;
  final double price;
}

/// Screen 14 (`14._bakiye_y_kle`): Balance & Monthly Subscription (`Abonman Yükle`)
/// Top-Up tab with preset TL amounts, custom amount validation (`Min ₺20 - Max ₺1.000`),
/// Monthly Subscription packages (`+200`, `+100`, `+50` passes), payment method
/// selector, and live projected summary.
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '150',
  );
  double _selectedAmount = 150.0;
  String? _validationError;
  bool _isSubscriptionMode = false;
  int _selectedPackageIndex = 0;

  static const List<double> _presets = <double>[1, 50, 100, 200];

  static const List<_SubscriptionPackageOption> _packages =
      <_SubscriptionPackageOption>[
    _SubscriptionPackageOption(
      title: 'Tam MaviHat Aylık Abonman',
      subtitle:
          '30 Gün Geçerli • 200 Geçiş Hakkı • Ayda 1 Kez (Hak Bitince veya Sonraki Ay) Yüklenebilir',
      addedPasses: TransitCard.monthlySubscriptionPasses,
      price: TransitCard.monthlySubscriptionPrice,
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(double value) {
    setState(() {
      _selectedAmount = value;
      _amountController.text = value.toInt().toString();
      _validationError = null;
    });
  }

  void _onCustomAmountChanged(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    final validator = ref.read(validateTopUpAmountUseCaseProvider);
    final res = validator(parsed);

    setState(() {
      if (parsed != null) {
        _selectedAmount = parsed;
      }
      _validationError = res.failureOrNull?.message;
    });
  }

  void _continueToConfirm() {
    final parsed = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );
    final validator = ref.read(validateTopUpAmountUseCaseProvider);
    final res = validator(parsed);

    res.fold(
      onFailure: (f) {
        setState(() => _validationError = f.message);
      },
      onSuccess: (validAmount) {
        final methods = ref.read(paymentMethodsControllerProvider);
        if (methods.isEmpty) {
          context.push(RouteNames.addPaymentCard);
          return;
        }
        ref.read(topUpDraftControllerProvider.notifier).setAmount(validAmount);
        context.push(RouteNames.confirmTopUp);
      },
    );
  }

  void _continueToSubscriptionConfirm() {
    final card = ref.read(transitCardControllerProvider);
    if (!card.canLoadSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bu ay için aktif abonmanınız devam ediyor (${card.subscriptionRemaining} geçiş hakkı kaldı). Haklarınız bittiğinde veya bir sonraki ay tekrar yükleyebilirsiniz.',
          ),
        ),
      );
      return;
    }
    final methods = ref.read(paymentMethodsControllerProvider);
    if (methods.isEmpty) {
      context.push(RouteNames.addPaymentCard);
      return;
    }
    final pkg = _packages[_selectedPackageIndex];
    ref.read(topUpDraftControllerProvider.notifier).setSubscriptionPackage(
          price: pkg.price,
          passes: pkg.addedPasses,
          title: pkg.title,
        );
    context.push(RouteNames.confirmTopUp);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final methods = ref.watch(paymentMethodsControllerProvider);
    final draft = ref.watch(topUpDraftControllerProvider);

    final selectedMethod = methods
            .where((m) => m.id == draft.paymentMethodId)
            .firstOrNull ??
        (methods.isNotEmpty ? methods.first : null);

    final projectedBalance = card.balance + _selectedAmount;
    final selectedPkg = _packages[_selectedPackageIndex];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const MaviHatHeader(
                title: 'Bakiye & Abonman Yükle',
                trailing: StatusPill(
                  label: 'KOMİSYONSUZ DOLUM',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Mode Selector: TL Bakiye Yükle vs Abonman Yükle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  setState(() => _isSubscriptionMode = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !_isSubscriptionMode
                                      ? scheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'TL Bakiye Yükle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: !_isSubscriptionMode
                                        ? Colors.white
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  setState(() => _isSubscriptionMode = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _isSubscriptionMode
                                      ? scheme.secondary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Abonman Yükle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: _isSubscriptionMode
                                        ? Colors.white
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Target Card Summary Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'YÜKLENECEK KART',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${card.alias} (${card.maskedNumber})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Bakiye: ${CurrencyFormatter.formatTl(card.balance)} • Abonman: ${card.subscriptionRemaining} Hak',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFA9EFED),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go(RouteNames.myCard),
                            child: const Text('Kart Değiştir'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (card.isUnpaired) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.add_card_rounded, color: scheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bakiye veya abonman yükleyebilmek için önce Kartım sekmesinden fiziksel ulaşım kartınızı eşleştirmelisiniz.',
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (card.isLocked) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.lock_rounded, color: scheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bu kart kilitli durumda olduğu için işlem yapılamaz. Önce Kartım sekmesinden kilidi kaldırın.',
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_isSubscriptionMode) ...<Widget>[
                      Text(
                        'Hızlı Tutar Seçin',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _presets.map((amt) {
                          final selected = _selectedAmount == amt &&
                              _validationError == null;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: amt == _presets.last ? 0 : 8,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _selectPreset(amt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? scheme.primary
                                        : mavi.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.outlineVariant
                                              .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Text(
                                    '₺${amt.toInt()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Özel Tutar Girin (Min: ₺1 - Maks: ₺1.000)',
                        controller: _amountController,
                        hintText: '150',
                        errorText: _validationError,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.currency_lira_rounded,
                        onChanged: _onCustomAmountChanged,
                        suffix: IconButton(
                          tooltip: 'Tutarı Temizle',
                          onPressed: () {
                            _amountController.clear();
                            _onCustomAmountChanged('');
                          },
                          icon: const Icon(Icons.clear_rounded, size: 18),
                        ),
                      ),
                    ] else ...<Widget>[
                      Text(
                        'Aylık Abonman Paketi (Ayda 1 Kez Dolum)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (card.hasActiveSubscription) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: mavi.tertiaryFixed,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.info_outline_rounded,
                                color: mavi.onTertiaryFixed,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bu ay için aktif abonmanınız devam ediyor (Kalan: ${card.subscriptionRemaining} / ${card.subscriptionTotal} Geçiş Hakkı • Bitiş: ${card.subscriptionRenewsAt}). Aylık abonman (₺260,00) ayda yalnızca 1 kez yüklenebilir; mevcut geçiş haklarınız bittiğinde veya bir sonraki ay tekrar yükleme yapabilirsiniz.',
                                  style: TextStyle(
                                    color: mavi.onTertiaryFixed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!card.isUnpaired && !card.isLocked) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: mavi.secondaryFixed.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: scheme.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Kartınızda aktif abonman hakkı bulunmuyor (0 Hak). ₺260,00 ödeyerek 30 gün geçerli 200 geçişlik yeni aylık abonmanınızı hemen yükleyebilirsiniz.',
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      for (int i = 0; i < _packages.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                setState(() => _selectedPackageIndex = i),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: mavi.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedPackageIndex == i
                                      ? scheme.secondary
                                      : scheme.outlineVariant
                                          .withValues(alpha: 0.4),
                                  width: _selectedPackageIndex == i ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    _selectedPackageIndex == i
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: _selectedPackageIndex == i
                                        ? scheme.secondary
                                        : scheme.outline,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          _packages[i].title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _packages[i].subtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
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
                                          _packages[i].price,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: scheme.primary,
                                        ),
                                      ),
                                      StatusPill(
                                        label: '${_packages[i].addedPasses} HAK',
                                        tone: StatusPillTone.teal,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),
                    // Selected Payment Method Box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Ödeme Yöntemi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(RouteNames.paymentMethods),
                          child: const Text('Değiştir / Yönet'),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(RouteNames.paymentMethods),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: mavi.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: selectedMethod != null
                            ? Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: mavi.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.credit_card_rounded,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          selectedMethod.bankName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          '${selectedMethod.maskedDisplay} • SKT ${selectedMethod.formattedExpiry}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              )
                            : const Row(
                                children: <Widget>[
                                  Icon(Icons.add_card_rounded),
                                  SizedBox(width: 10),
                                  Text(
                                    'Yeni Ödeme Kartı Ekle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Live Summary Breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: !_isSubscriptionMode
                          ? Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Yüklenecek Tutar',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatTl(
                                        _selectedAmount,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Hizmet Bedeli',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '₺0,00 (Ücretsiz)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Yükleme Sonrası Tahmini Bakiye',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.formatTl(
                                        projectedBalance,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Tanımlanacak Aylık Abonman',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${selectedPkg.addedPasses} Geçiş (30 Gün)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Yükleme Sonrası Toplam Hak',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${selectedPkg.addedPasses} Geçiş Hakkı',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Expanded(
                                      child: Text(
                                        'Ödenecek Abonman Tutarı',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.formatTl(
                                        selectedPkg.price,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isSubscriptionMode)
                      AppButton(
                        label:
                            'Devam Et (${CurrencyFormatter.formatTl(_selectedAmount)})',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: card.isLocked || card.isUnpaired
                            ? null
                            : _continueToConfirm,
                      )
                    else
                      AppButton(
                        label: card.hasActiveSubscription
                            ? 'Aktif Abonman Mevcut (${card.subscriptionRemaining} Hak Kaldı)'
                            : 'Ödeme Ekranına Geç (${selectedPkg.addedPasses} Geçiş • ${CurrencyFormatter.formatTl(selectedPkg.price)})',
                        icon: Icons.confirmation_number_rounded,
                        trailingIcon: card.canLoadSubscription
                            ? Icons.arrow_forward_rounded
                            : null,
                        onPressed: card.canLoadSubscription
                            ? _continueToSubscriptionConfirm
                            : null,
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
