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

/// Screen 13 (`13._i_lem_detay`): Transaction Detail Receipt screen with
/// reference copy, station validator log coordinates, and dispute report modal.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  Future<void> _showDisputeModal(
    BuildContext context,
    WidgetRef ref,
    String txnId,
    String referenceCode,
  ) async {
    final descCtrl = TextEditingController();
    String selectedReason = 'Mükerrer / Çift Çekim';
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'İşlem İtirazı / Sorun Bildir ($referenceCode)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Sorun Nedeni',
                      border: OutlineInputBorder(),
                    ),
                    items: const <String>[
                      'Mükerrer / Çift Çekim',
                      'Aktarma İndirimi Uygulanmadı',
                      'Bakiye Kartıma Yansımadı',
                      'Hatalı İstasyon / Turnike Kaydı',
                    ]
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => selectedReason = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Açıklamanız',
                    controller: descCtrl,
                    hintText: 'Yaşadığınız sorunu kısaca yazın...',
                    errorText: errorText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'İtiraz Kaydını Gönder',
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      final res =
                          await ref.read(submitTransactionDisputeUseCaseProvider)(
                        transactionId: txnId,
                        reason: selectedReason,
                        description: descCtrl.text,
                      );
                      res.fold(
                        onFailure: (f) =>
                            setModalState(() => errorText = f.message),
                        onSuccess: (dispute) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'İtiraz talebiniz alındı (Kayıt No: ${dispute.id}).',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final txns = ref.watch(transactionsControllerProvider);
    final txn = txns
            .where(
              (t) => t.id == transactionId || t.referenceCode == transactionId,
            )
            .firstOrNull ??
        txns.first;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'İşlem Detayı',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: IconButton(
                  tooltip: 'Makbuzu Paylaş',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${txn.referenceCode} işlem makbuzu panoya kopyalandı.',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.share_rounded, color: scheme.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Top Receipt Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: <Widget>[
                          const StatusPill(
                            label: 'TAMAMLANDI • ONAYLI İŞLEM',
                            tone: StatusPillTone.teal,
                            showDot: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyFormatter.formatTl(
                              txn.amount,
                              showSign: true,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: txn.isCredit
                                      ? scheme.secondary
                                      : scheme.primary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            txn.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${txn.displayDateGroup} • Saat ${txn.displayTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: txn.referenceCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Referans kodu kopyalandı: ${txn.referenceCode}',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: mavi.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'Ref: ${txn.referenceCode}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.copy_rounded, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Receipt Breakdown Rows
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          _DetailKeyValueRow(
                            label: 'Ulaşım Hattı',
                            value: txn.lineCode,
                          ),
                          const Divider(height: 20),
                          _DetailKeyValueRow(
                            label: 'Turnike / Validator Cihazı',
                            value: txn.validatorCode,
                          ),
                          const Divider(height: 20),
                          _DetailKeyValueRow(
                            label: 'Tarife Türü',
                            value: txn.tariffType,
                          ),
                          const Divider(height: 20),
                          _DetailKeyValueRow(
                            label: 'Kullanılan Kart',
                            value: 'MaviHat ${txn.maskedCardNumber}',
                          ),
                          const Divider(height: 20),
                          _DetailKeyValueRow(
                            label: 'İşlem Sonrası Kalan Bakiye',
                            value: CurrencyFormatter.formatTl(txn.balanceAfter),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Station Location Card (Explicitly labelled as Validator Log, not live GPS)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'İşlem Noktası (Turnike Kaydı)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context.go(RouteNames.map),
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Haritada Aç'),
                              ),
                            ],
                          ),
                          Text(
                            '${txn.title} (${txn.latitude.toStringAsFixed(4)}, ${txn.longitude.toStringAsFixed(4)})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bilgi: Bu konum, fiziksel kartın canlı GPS takibi değil; kartın okutulduğu istasyon/turnike cihazının kayıtlı konumudur.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Makbuzu Paylaş / Kopyala',
                      icon: Icons.receipt_long_rounded,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'MaviHat Makbuz: ${txn.title} | ${CurrencyFormatter.formatTl(txn.amount, showSign: true)} | Ref: ${txn.referenceCode}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'İşlem makbuz özeti panoya kopyalandı.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Bu işlemle ilgili sorun mu var? İtiraz Et',
                      variant: AppButtonVariant.tonal,
                      icon: Icons.report_problem_outlined,
                      onPressed: () => _showDisputeModal(
                        context,
                        ref,
                        txn.id,
                        txn.referenceCode,
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

class _DetailKeyValueRow extends StatelessWidget {
  const _DetailKeyValueRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

