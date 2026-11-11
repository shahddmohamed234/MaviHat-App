import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../transactions/domain/entities/transit_transaction.dart';
import '../../domain/entities/transit_card.dart';

/// Opens the 2-minute dynamic QR payment sheet (`QrPaymentSheet`) with
/// automatic 30-second QR rotation and automatic memory-safe dismissal at 00:00.
Future<void> showQrPaymentSheet(BuildContext context) async {
  ScaffoldMessenger.of(context).clearSnackBars();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const QrPaymentSheet(),
  );
}

class QrPaymentSheet extends ConsumerStatefulWidget {
  const QrPaymentSheet({super.key});

  @override
  ConsumerState<QrPaymentSheet> createState() => _QrPaymentSheetState();
}

class _QrPaymentSheetState extends ConsumerState<QrPaymentSheet> {
  static const int _totalDurationSeconds = 120; // 2 minutes total
  static const int _rotationIntervalSeconds = 30; // Rotates every 30 seconds
  static const double _standardFullFareTl = 20.00; // Sabit Tam Biniş Tarifesi

  Timer? _timer;
  int _remainingSeconds = _totalDurationSeconds;
  int _manualRefreshBonus = 0;
  bool _isProcessingPass = false;
  String? _errorText;
  String? _lastPassSuccessBanner;
  late AutoValidatorTerminal _detectedTerminal;

  @override
  void initState() {
    super.initState();
    // Automatically detect the next station validator in the Istanbul network
    // so every new QR session boards at a new station along the route!
    final currentCard = ref.read(transitCardControllerProvider);
    _detectedTerminal = AutoValidatorTerminal.nextTerminalAfter(
      currentCard.lastStationName,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        // 2-minute session finished: cancel timer and close sheet immediately to free memory
        timer.cancel();
        _timer = null;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  /// Current 30-second rotation index (0, 1, 2, 3) + manual refresh seed.
  int get _rotationStep =>
      ((_totalDurationSeconds - _remainingSeconds) ~/
          _rotationIntervalSeconds) +
      _manualRefreshBonus;

  /// Seconds remaining until the next 30-second QR code rotation.
  int get _secondsUntilRotation {
    final elapsedInCycle =
        (_totalDurationSeconds - _remainingSeconds) % _rotationIntervalSeconds;
    return _rotationIntervalSeconds - elapsedInCycle;
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
      _manualRefreshBonus++;
      _errorText = null;
      _lastPassSuccessBanner = null;
    });
  }

  Future<void> _executeQrTurnstilePass({
    required int tapNumber,
    required bool willUseSubscription,
  }) async {
    setState(() {
      _isProcessingPass = true;
      _errorText = null;
    });

    final res = await ref
        .read(transitCardControllerProvider.notifier)
        .executeTurnstilePass(
          stationName: _detectedTerminal.stationName,
          lineDescription: _detectedTerminal.lineDescription,
          category: _detectedTerminal.category,
          fareAmount: _standardFullFareTl,
          methodLabel: 'QR Kod Ödeme',
          latitude: _detectedTerminal.lat,
          longitude: _detectedTerminal.lng,
          useSubscription: willUseSubscription,
        );

    if (!mounted) return;
    setState(() => _isProcessingPass = false);

    res.fold(
      onFailure: (f) {
        setState(() => _errorText = f.message);
      },
      onSuccess: (updatedCard) {
        setState(() {
          _manualRefreshBonus++;
          _lastPassSuccessBanner = willUseSubscription
              ? '1. Basım Başarılı (${_detectedTerminal.stationName}): Aylık abonmandan 1 hak düşüldü (Kalan: ${updatedCard.subscriptionRemaining}). Aynı turnikede tekrar okutursanız 2., 3., 4., 5. basım TL bakiyeden çekilir.'
              : '$tapNumber. Basım Başarılı (${_detectedTerminal.stationName}): TL bakiyeden -${CurrencyFormatter.formatTl(_standardFullFareTl)} çekildi (Kalan Bakiye: ${CurrencyFormatter.formatTl(updatedCard.balance)}).';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);
    final txns = ref.watch(transactionsControllerProvider);

    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final step = _rotationStep;
    final rotSecs = _secondsUntilRotation;
    final tokenCode =
        'MVH-QR-${card.lastFour}-C${step + 1}-${(1000 + step * 379) % 9000}';

    final nextTapNumber = _countConsecutiveTapsAtDetectedTerminal(txns) + 1;
    final willUseSubscription =
        nextTapNumber == 1 && card.subscriptionRemaining > 0;

    return Container(
      decoration: BoxDecoration(
        color: mavi.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: StatusPill(
                      label: 'OTOMATİK VALİDATÖR ALGILAMA • QR ÖDEME',
                      tone: StatusPillTone.teal,
                      showDot: true,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () {
                      _timer?.cancel();
                      _timer = null;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'QR Kodu Turnike Kamerasına Okutun',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bindiğiniz istasyon turnike makinesi tarafından otomatik algılanır. QR kod her 30 saniyede bir değişir ve 2 dakika sonunda otomatik kapanır.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              // Dynamic 21x21 QR Code Matrix Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: 186,
                      height: 186,
                      child: CustomPaint(
                        painter: _DynamicQrMatrixPainter(
                          seed: step * 97 + card.lastFour.hashCode,
                          primaryColor: const Color(0xFF002642),
                          accentColor: const Color(0xFF006767),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tokenCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF002642),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 2-Minute Session Timer + 30-Second Auto-Rotation Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mavi.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Toplam Süre: $mins:$secs / 02:00',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Yeni QR: $rotSecs sn (Döngü #${step + 1})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: scheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: rotSecs / _rotationIntervalSeconds,
                        minHeight: 6,
                        backgroundColor: mavi.surfaceContainerHighest,
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!card.isUnpaired && !card.isLocked) ...<Widget>[
                const SizedBox(height: 10),
                // Automatically Detected Turnstile Machine Badge + Switch Terminal Option
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mavi.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.sensors_rounded,
                        color: scheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
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
                                fontSize: 12.5,
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              '${_detectedTerminal.lineDescription} • ${_detectedTerminal.validatorCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _detectNextTurnstileTerminal,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text(
                          'Farklı Durak',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mavi.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
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
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          willUseSubscription
                              ? 'Sıradaki Geçiş: 1. Basım • İlk basımda otomatik olarak Aylık Abonmandan 1 hak düşer (Kalan: ${card.subscriptionRemaining} Hak). Aynı turnikede 2., 3., 4., 5. basımlarda ₺20,00 TL çekilir.'
                              : nextTapNumber >= 2
                                  ? 'Sıradaki Geçiş: $nextTapNumber. Basım • Aynı turnikede arka arkaya basıldığı için $nextTapNumber. basım otomatik olarak TL bakiyeden (${CurrencyFormatter.formatTl(_standardFullFareTl)}) çekilir.'
                                  : 'Sıradaki Geçiş: 1. Basım • Abonman hakkınız kalmadığı için geçiş ücreti (${CurrencyFormatter.formatTl(_standardFullFareTl)}) TL bakiyeden çekilir.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_lastPassSuccessBanner != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mavi.secondaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        color: mavi.onSecondaryFixed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastPassSuccessBanner!,
                          style: TextStyle(
                            color: mavi.onSecondaryFixed,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorText != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
                      label: willUseSubscription
                          ? 'Turnikede Okut (1. Basım • Abonman)'
                          : 'Turnikede Okut ($nextTapNumber. Basım • ${CurrencyFormatter.formatTl(_standardFullFareTl)})',
                      icon: Icons.qr_code_scanner_rounded,
                      isLoading: _isProcessingPass,
                      onPressed: card.isUnpaired || card.isLocked
                          ? null
                          : () => _executeQrTurnstilePass(
                                tapNumber: nextTapNumber,
                                willUseSubscription: willUseSubscription,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _manualRefreshBonus++;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('QR Kodu Şimdi Yenile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicQrMatrixPainter extends CustomPainter {
  const _DynamicQrMatrixPainter({
    required this.seed,
    required this.primaryColor,
    required this.accentColor,
  });

  final int seed;
  final Color primaryColor;
  final Color accentColor;

  bool _isFinderPattern(int r, int c, int grid) {
    final topLeft = r < 7 && c < 7;
    final topRight = r < 7 && c >= grid - 7;
    final bottomLeft = r >= grid - 7 && c < 7;
    return topLeft || topRight || bottomLeft;
  }

  void _drawFinder(Canvas canvas, double x, double y, double cell, Color color) {
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell;
    canvas.drawRect(
      Rect.fromLTWH(x + cell * 0.5, y + cell * 0.5, cell * 6, cell * 6),
      outerPaint,
    );
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x + cell * 2, y + cell * 2, cell * 3, cell * 3),
      innerPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 21;
    final cell = size.width / grid;
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    _drawFinder(canvas, 0, 0, cell, primaryColor);
    _drawFinder(canvas, (grid - 7) * cell, 0, cell, primaryColor);
    _drawFinder(canvas, 0, (grid - 7) * cell, cell, accentColor);

    for (var r = 0; r < grid; r++) {
      for (var c = 0; c < grid; c++) {
        if (_isFinderPattern(r, c, grid)) continue;
        // Center emblem clearance
        if (r >= 9 && r <= 11 && c >= 9 && c <= 11) {
          if (r == 10 && c == 10) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(c * cell, r * cell, cell, cell),
                const Radius.circular(2),
              ),
              Paint()..color = accentColor,
            );
          }
          continue;
        }
        final hash = ((r * 31 + c * 17 + seed * 13) ^ (r * c + seed)) & 0xFF;
        if (hash % 3 != 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cell + 0.5,
                r * cell + 0.5,
                cell - 1.0,
                cell - 1.0,
              ),
              const Radius.circular(1.8),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicQrMatrixPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
