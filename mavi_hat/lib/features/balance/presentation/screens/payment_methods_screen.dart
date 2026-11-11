import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/balance_entities.dart';

/// Screen 15 (`15._deme_y_ntemlerim`): Saved Payment Methods management screen
/// with default card selection, delete confirmation, interactive Automatic
/// Balance Top-Up instruction (`Otomatik Bakiye Yükleme Talimatı`), and
/// navigation to Add Card (`16._yeni_kart_ekle`).
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isExecutingAutoTopUp = false;

  Future<void> _confirmDelete(
    BuildContext context,
    String methodId,
    String displayLabel,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kayıtlı Kartı Sil'),
        content: Text(
          '$displayLabel kartını kayıtlı ödeme yöntemlerinizden kaldırmak istediğinize emin misiniz?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(paymentMethodsControllerProvider.notifier)
                  .removeCard(methodId);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$displayLabel başarıyla kaldırıldı.'),
                  ),
                );
              }
            },
            child: const Text('Kartı Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerAutoTopUpIfEligible({
    required bool forceExecute,
    required double threshold,
    required double amount,
  }) async {
    final card = ref.read(transitCardControllerProvider);
    final methods = ref.read(paymentMethodsControllerProvider);
    if (card.isUnpaired || card.isLocked || methods.isEmpty) {
      if (forceExecute && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Otomatik dolum için aktif bir ulaşım kartı ve kayıtlı banka kartı gereklidir.',
            ),
          ),
        );
      }
      return;
    }

    if (!forceExecute && card.balance >= threshold) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Otomatik talimat aktif edildi: Bakiyeniz ${CurrencyFormatter.formatTl(threshold)} altına düştüğünde otomatik ${CurrencyFormatter.formatTl(amount)} yüklenecektir.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isExecutingAutoTopUp = true);
    final defaultMethod =
        ref.read(paymentMethodsControllerProvider.notifier).defaultMethod ??
            methods.first;

    final res = await ref.read(confirmTopUpPaymentUseCaseProvider)(
      request: TopUpRequest(
        cardId: card.id,
        amount: amount,
        paymentMethodId: defaultMethod.id,
        orderReference:
            'MVH-AUTO-${DateTime.now().millisecondsSinceEpoch % 100000}',
      ),
      otpCode: '123456',
    );

    if (!mounted) return;
    setState(() => _isExecutingAutoTopUp = false);

    res.fold(
      onFailure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      onSuccess: (topUpRes) {
        ref.read(transitCardControllerProvider.notifier).refresh();
        ref.read(transactionsControllerProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Otomatik Bakiye Dolumu tamamlandı! +${CurrencyFormatter.formatTl(amount)} yüklendi (Yeni Bakiye: ${CurrencyFormatter.formatTl(topUpRes.updatedBalance)}).',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final methods = ref.watch(paymentMethodsControllerProvider);
    final draft = ref.watch(topUpDraftControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider);
    final card = ref.watch(transitCardControllerProvider);

    const thresholds = <double>[50.0, 100.0, 250.0];
    const amounts = <double>[100.0, 150.0, 250.0, 500.0];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Ödeme Yöntemlerim',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'TOKENİZE GÜVENLİK',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    if (methods.isEmpty)
                      AppEmptyView(
                        icon: Icons.credit_card_off_rounded,
                        title: 'Kayıtlı ödeme kartınız yok',
                        subtitle:
                            'Hızlı bakiye yüklemek için yeni bir banka veya kredi kartı ekleyebilirsiniz.',
                        actionLabel: 'Yeni Kart Ekle',
                        onAction: () => context.push(RouteNames.addPaymentCard),
                      )
                    else
                      for (final method in methods)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: mavi.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                ref
                                    .read(topUpDraftControllerProvider.notifier)
                                    .setPaymentMethod(method.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: draft.paymentMethodId == method.id
                                        ? scheme.secondary
                                        : scheme.outlineVariant
                                            .withValues(alpha: 0.4),
                                    width: draft.paymentMethodId == method.id
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      draft.paymentMethodId == method.id
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: draft.paymentMethodId == method.id
                                          ? scheme.secondary
                                          : scheme.outline,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Flexible(
                                                child: Text(
                                                  method.bankName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (method.isDefault) ...<Widget>[
                                                const SizedBox(width: 8),
                                                const StatusPill(
                                                  label: 'VARSAYILAN',
                                                  tone: StatusPillTone.teal,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${method.maskedDisplay} • SKT ${method.formattedExpiry}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Kart Seçenekleri',
                                      onSelected: (action) {
                                        if (action == 'default') {
                                          ref
                                              .read(
                                                paymentMethodsControllerProvider
                                                    .notifier,
                                              )
                                              .setDefault(method.id);
                                        } else if (action == 'delete') {
                                          _confirmDelete(
                                            context,
                                            method.id,
                                            method.maskedDisplay,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) =>
                                          <PopupMenuEntry<String>>[
                                        if (!method.isDefault)
                                          const PopupMenuItem<String>(
                                            value: 'default',
                                            child: Text('Varsayılan Yap'),
                                          ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Kartı Sil'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Yeni Kart Ekle',
                      variant: AppButtonVariant.tonal,
                      icon: Icons.add_card_rounded,
                      onPressed: () => context.push(RouteNames.addPaymentCard),
                    ),
                    const SizedBox(height: 18),
                    // Interactive Automatic Balance Top-Up Setting Card
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Otomatik Bakiye Yükleme Talimatı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Bakiye ₺${prefs.autoTopUpThreshold.toInt()} altına düştüğünde otomatik ₺${prefs.autoTopUpAmount.toInt()} yükle.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              value: prefs.autoTopUpEnabled,
                              onChanged: (val) async {
                                final updated =
                                    prefs.copyWith(autoTopUpEnabled: val);
                                await ref
                                    .read(
                                      preferencesControllerProvider.notifier,
                                    )
                                    .updatePreferences(updated);
                                if (val) {
                                  await _triggerAutoTopUpIfEligible(
                                    forceExecute: false,
                                    threshold: updated.autoTopUpThreshold,
                                    amount: updated.autoTopUpAmount,
                                  );
                                }
                              },
                            ),
                            if (prefs.autoTopUpEnabled) ...<Widget>[
                              const Divider(height: 18),
                              Text(
                                'ALT LİMİT (TETİKLEME TUTARI)',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: thresholds.map((t) {
                                  final selected =
                                      prefs.autoTopUpThreshold == t;
                                  return ChoiceChip(
                                    label: Text('₺${t.toInt()} Altında'),
                                    selected: selected,
                                    onSelected: (_) async {
                                      final updated = prefs.copyWith(
                                        autoTopUpThreshold: t,
                                      );
                                      await ref
                                          .read(
                                            preferencesControllerProvider
                                                .notifier,
                                          )
                                          .updatePreferences(updated);
                                      await _triggerAutoTopUpIfEligible(
                                        forceExecute: false,
                                        threshold: t,
                                        amount: updated.autoTopUpAmount,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'OTOMATİK YÜKLENECEK TUTAR',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: amounts.map((a) {
                                  final selected = prefs.autoTopUpAmount == a;
                                  return ChoiceChip(
                                    label: Text('+₺${a.toInt()}'),
                                    selected: selected,
                                    onSelected: (_) async {
                                      final updated = prefs.copyWith(
                                        autoTopUpAmount: a,
                                      );
                                      await ref
                                          .read(
                                            preferencesControllerProvider
                                                .notifier,
                                          )
                                          .updatePreferences(updated);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      'Mevcut Kart Bakiyesi: ${CurrencyFormatter.formatTl(card.balance)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isExecutingAutoTopUp
                                        ? null
                                        : () => _triggerAutoTopUpIfEligible(
                                              forceExecute: true,
                                              threshold:
                                                  prefs.autoTopUpThreshold,
                                              amount: prefs.autoTopUpAmount,
                                            ),
                                    icon: const Icon(
                                      Icons.bolt_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Şimdi Yükle (+₺${prefs.autoTopUpAmount.toInt()})',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Seçimi Onayla',
                      icon: Icons.check_circle_outline_rounded,
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
