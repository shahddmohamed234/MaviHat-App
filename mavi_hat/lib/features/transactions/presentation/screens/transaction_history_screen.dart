import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/transit_transaction.dart';

/// Screen 12 (`12._hareketlerim`): Full Transaction History screen with card
/// switcher, monthly spending summary, category filter chips, date grouping,
/// and pagination.
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  TransactionFilter _selectedFilter = TransactionFilter.all;
  int _visibleCount = 6;

  void _showMonthlyStatementDialog(
    List<TransitTransaction> allForCard,
    String cardAlias,
  ) {
    final totalSpent = allForCard
        .where((t) => t.amount < 0)
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());
    final totalTopUp = allForCard
        .where((t) => t.amount > 0)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aylık Hesap Özeti (Ekim 2026)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Kart: $cardAlias'),
            const SizedBox(height: 8),
            Text(
              'Toplam Ulaşım Harcaması: ${CurrencyFormatter.formatTl(totalSpent)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'Toplam Bakiye Dolumu: ${CurrencyFormatter.formatTl(totalTopUp)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Toplam İşlem Adedi: ${allForCard.length}'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ekim 2026 hesap özeti cihazınıza kaydedildi (Prototip).',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Özeti İndir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final activeCard = ref.watch(transitCardControllerProvider);
    final allCards = ref.read(transitCardControllerProvider.notifier).allCards;
    final filteredTxns = ref.watch(getTransactionHistoryUseCaseProvider).sync(
          cardId: activeCard.id,
          filter: _selectedFilter,
        );
    final allCardTxns = ref.watch(transactionsControllerProvider);

    final totalSpent = allCardTxns
        .where((t) => t.amount < 0)
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

    final displayedTxns = filteredTxns.take(_visibleCount).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Hareketlerim',
                showBackButton: true,
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.home);
                  }
                },
                trailing: IconButton(
                  tooltip: 'Aylık Hesap Özeti',
                  onPressed: () => _showMonthlyStatementDialog(
                    allCardTxns,
                    '${activeCard.alias} (${activeCard.maskedNumber})',
                  ),
                  icon: Icon(
                    Icons.sim_card_download_outlined,
                    color: scheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Card Selector Dropdown / Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: allCards.map((c) {
                          final selected = c.id == activeCard.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '${c.alias} ${c.maskedNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : scheme.onSurface,
                                ),
                              ),
                              selected: selected,
                              selectedColor: scheme.primary,
                              backgroundColor: mavi.surfaceContainerLow,
                              onSelected: (_) {
                                ref
                                    .read(transitCardControllerProvider.notifier)
                                    .selectCard(c.id);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Monthly Spending Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'EKİM 2026 ULAŞIM HARCAMASI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatTl(totalSpent),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mevcut Bakiye: ${CurrencyFormatter.formatTl(activeCard.balance)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFA9EFED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            onPressed: () => _showMonthlyStatementDialog(
                              allCardTxns,
                              '${activeCard.alias} (${activeCard.maskedNumber})',
                            ),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                            ),
                            label: const Text('Özet'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Filter Chips (`Tümü`, `Metro`, `Otobüs`, `Vapur`, `Yüklemeler`)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <(TransactionFilter, String)>[
                          (TransactionFilter.all, 'Tümü'),
                          (TransactionFilter.metro, 'Metro & Marmaray'),
                          (TransactionFilter.bus, 'Otobüs'),
                          (TransactionFilter.ferry, 'Vapur'),
                          (TransactionFilter.topUp, 'Yüklemeler'),
                        ].map((item) {
                          final isSelected = _selectedFilter == item.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                item.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isSelected
                                      ? Colors.white
                                      : scheme.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: scheme.secondary,
                              backgroundColor: mavi.surfaceContainerLow,
                              checkmarkColor: Colors.white,
                              onSelected: (_) {
                                setState(() {
                                  _selectedFilter = item.$1;
                                  _visibleCount = 6;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (displayedTxns.isEmpty)
                      AppEmptyView(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'Bu kategoride işlem bulunamadı',
                        subtitle:
                            'Seçtiğiniz ulaşım filtresine ait kayıtlı bir hareket yok.',
                        actionLabel: 'Tüm İşlemleri Göster',
                        onAction: () {
                          setState(
                            () => _selectedFilter = TransactionFilter.all,
                          );
                        },
                      )
                    else ...<Widget>[
                      for (int i = 0; i < displayedTxns.length; i++) ...<Widget>[
                        if (i == 0 ||
                            displayedTxns[i].displayDateGroup !=
                                displayedTxns[i - 1].displayDateGroup)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text(
                              displayedTxns[i].displayDateGroup,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        _HistoryRowCard(
                          transaction: displayedTxns[i],
                          onTap: () => context.push(
                            '${RouteNames.transactionDetail}?id=${displayedTxns[i].id}',
                          ),
                        ),
                      ],
                      if (filteredTxns.length > _visibleCount) ...<Widget>[
                        const SizedBox(height: 8),
                        AppButton(
                          label:
                              'Daha Fazla Göster (${filteredTxns.length - _visibleCount})',
                          variant: AppButtonVariant.tonal,
                          height: 46,
                          onPressed: () {
                            setState(() => _visibleCount += 10);
                          },
                        ),
                      ],
                    ],
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

class _HistoryRowCard extends StatelessWidget {
  const _HistoryRowCard({
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
    final IconData icon = transaction.category == 'topUp'
        ? Icons.add_card_rounded
        : (transaction.category == 'tram' ||
                combinedText.contains('tramvay') ||
                combinedText.contains('tünel'))
            ? Icons.tram_rounded
            : (transaction.category == 'metro' ||
                    combinedText.contains('metro') ||
                    combinedText.contains('marmaray'))
                ? Icons.subway_rounded
                : (transaction.category == 'bus' ||
                        combinedText.contains('iett') ||
                        combinedText.contains('otobüs') ||
                        combinedText.contains('metrobüs'))
                    ? Icons.directions_bus_filled_rounded
                    : (transaction.category == 'ferry' ||
                            combinedText.contains('iskele') ||
                            combinedText.contains('vapur'))
                        ? Icons.directions_boat_filled_rounded
                        : Icons.directions_transit_filled_rounded;

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
                    color: mavi.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
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
                    const StatusPill(
                      label: 'TAMAMLANDI',
                      tone: StatusPillTone.neutral,
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
