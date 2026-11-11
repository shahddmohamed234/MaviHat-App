import 'dart:math' as math;

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
import '../../../../core/widgets/mavihat_logo.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/transit_card.dart';
import '../widgets/qr_payment_sheet.dart';

/// Screens 9, 10 & 23:
/// - `9._kart_m_n_y_z` (Kartım Front Face — Authentic Istanbul Transit Card)
/// - `10._kart_m_arka_y_z` (Kartım Back Face — Personalized Citizen Transit ID)
/// - `23._kart_kilitlendi` (Locked Card state + SMS OTP Unlock Modal Sheet)
/// - Unpaired Physical Card Pairing Onboarding for newly created accounts
class MyCardScreen extends ConsumerStatefulWidget {
  const MyCardScreen({super.key});

  @override
  ConsumerState<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends ConsumerState<MyCardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  final TextEditingController _pairSerialController = TextEditingController();
  final TextEditingController _pairAliasController = TextEditingController();
  bool _showingBack = false;
  bool _isPairing = false;
  String? _pairError;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pairSerialController.dispose();
    _pairAliasController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() => _showingBack = !_showingBack);
    if (_showingBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Future<void> _submitInlineCardPairing() async {
    setState(() {
      _isPairing = true;
      _pairError = null;
    });

    final res = await ref
        .read(transitCardControllerProvider.notifier)
        .pairPhysicalCard(
          serialNumber: _pairSerialController.text,
          alias: _pairAliasController.text,
        );

    if (!mounted) return;
    setState(() => _isPairing = false);

    res.fold(
      onFailure: (f) => setState(() => _pairError = f.message),
      onSuccess: (paired) {
        _pairSerialController.clear();
        _pairAliasController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${paired.alias} (${paired.maskedNumber}) ulaşım kartınız başarıyla eşleştirildi!',
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUnlockCardSheet(TransitCard card) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    final otpCtrl = TextEditingController();
    String? errorText;
    bool isUnlocking = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 36,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const StatusPill(
                    label: 'SMS GÜVENLİK DOĞRULAMASI (ÖRNEK KOD: 123456)',
                    tone: StatusPillTone.teal,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kart Kilidini Kaldır (${card.maskedNumber})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kayıtlı cep telefonunuza gönderilen 6 haneli SMS doğrulama kodunu girerek kartınızı tekrar aktif hale getirebilirsiniz.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: '6 Haneli SMS Doğrulama Kodu',
                    hintText: 'Örn: 123456',
                    controller: otpCtrl,
                    errorText: errorText,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.sms_outlined,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Doğrula ve Kilidi Kaldır',
                    icon: Icons.lock_open_rounded,
                    isLoading: isUnlocking,
                    onPressed: () async {
                      setModalState(() {
                        isUnlocking = true;
                        errorText = null;
                      });
                      final res = await ref
                          .read(transitCardControllerProvider.notifier)
                          .unlockCard(otpCtrl.text);
                      if (!mounted) return;
                      res.fold(
                        onFailure: (f) {
                          setModalState(() {
                            isUnlocking = false;
                            errorText = f.message;
                          });
                        },
                        onSuccess: (_) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kart kilidi başarıyla kaldırıldı. Kartınız tekrar kullanıma açık.',
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

  Future<void> _showPairPhysicalCardDialog() async {
    final aliasCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Fiziksel Ulaşım Kartı Eşleştir / Güncelle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppTextField(
                      label: 'Kart Rumuzu',
                      controller: aliasCtrl,
                      hintText: 'Örn: İstanbul Şehir Kartım',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: '16 Haneli Kart Seri No (veya Son 4 Hane)',
                      controller: serialCtrl,
                      hintText: 'Örn: 6370 3400 1234 4821',
                      errorText: dialogError,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final res = await ref
                        .read(transitCardControllerProvider.notifier)
                        .pairPhysicalCard(
                          serialNumber: serialCtrl.text,
                          alias: aliasCtrl.text,
                        );
                    res.fold(
                      onFailure: (f) =>
                          setDialogState(() => dialogError = f.message),
                      onSuccess: (_) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fiziksel ulaşım kartınız başarıyla eşleştirildi.',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Eşleştir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSubscriptionDetailSheet(TransitCard card) {
    final mavi = context.maviTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: mavi.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const StatusPill(
              label: 'AYLIK MAVİHAT ABONMAN PAKETİ',
              tone: StatusPillTone.teal,
            ),
            const SizedBox(height: 10),
            Text(
              'Kalan Geçiş Hakkı: ${card.subscriptionRemaining} / ${card.subscriptionTotal}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Son Geçerlilik Tarihi: ${card.subscriptionRenewsAt}\n'
              'Kullanılan: ${card.subscriptionUsed} / ${card.subscriptionTotal} Geçiş • Kalan: ${card.subscriptionRemaining} Hak\n'
              'Abonman yükleme işlemlerinizi Yükle sekmesinden gerçekleştirebilirsiniz.',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Abonman Kurallarını İncele',
              variant: AppButtonVariant.tonal,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(
                  '${RouteNames.helpArticleDetail}?id=art_subscription_rules',
                );
              },
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Kartım',
                trailing: StatusPill(
                  label: card.isUnpaired
                      ? 'KART YOK'
                      : card.isLocked
                          ? 'KİLİTLİ'
                          : 'AKTİF',
                  tone: card.isUnpaired || card.isLocked
                      ? StatusPillTone.danger
                      : StatusPillTone.teal,
                  showDot: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontalPadding,
                ),
                child: card.isUnpaired
                    ? _buildUnpairedCardOnboarding(context, scheme, mavi)
                    : _buildPairedCardContent(context, scheme, mavi, card),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnpairedCardOnboarding(
    BuildContext context,
    ColorScheme scheme,
    MaviHatThemeExtension mavi,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
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
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'Fiziksel Ulaşım Kartınızı Eşleştirin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hesabınıza henüz bir İstanbul ulaşım kartı tanımlanmadı. Kartınızın üzerindeki seri numarasını girerek hemen eşleştirin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_pairError != null) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _pairError!,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        AppTextField(
          label: 'Kart Rumuzu (Örn: Kişisel İstanbulkartım)',
          controller: _pairAliasController,
          hintText: 'İstanbul Şehir Kartım',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Fiziksel Kart Seri Numarası',
          controller: _pairSerialController,
          hintText: '6370 3400 1234 4821',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.numbers_rounded,
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Kartı Eşleştir ve Aktifleştir',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isPairing,
          onPressed: _submitInlineCardPairing,
        ),
      ],
    );
  }

  Widget _buildPairedCardContent(
    BuildContext context,
    ColorScheme scheme,
    MaviHatThemeExtension mavi,
    TransitCard card,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 3D Animated Authentic Istanbul Transit Card View (Front & Back)
        GestureDetector(
          onTap: _toggleFlip,
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, _) {
              final angle = _flipController.value * math.pi;
              final isBack = angle > (math.pi / 2);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _CardBackFace(card: card),
                      )
                    : _CardFrontFace(card: card),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Explicit Accessible Flip Button (Mandatory per design.md)
        Center(
          child: OutlinedButton.icon(
            onPressed: _toggleFlip,
            icon: const Icon(Icons.flip_camera_android_rounded),
            label: Text(
              _showingBack ? 'Ön yüzü göster' : 'Kartın arkasını gör',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Locked State Warning Box (Screen 23 `23._kart_kilitlendi`)
        if (card.isLocked) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.lock_rounded,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kartınız Güvenlik Kilidi Altında',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mevcut ${CurrencyFormatter.formatTl(card.balance)} bakiyeniz ve ${card.subscriptionRemaining} abonman geçiş hakkınız korumaya alındı. Kilitli karta bakiye yüklenemez ve turnike geçişi yapılamaz.',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Kart Kilidini Kaldır (SMS Doğrulama)',
                  icon: Icons.lock_open_rounded,
                  onPressed: () => _showUnlockCardSheet(card),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(RouteNames.helpAndFaq),
                        child: const Text('ALO 153 Kayıp İhbarı'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push(RouteNames.transactionHistory),
                        child: const Text('Hareketleri İncele'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        // Primary Card Operations Row
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Bakiye Yükle',
                icon: Icons.add_card_rounded,
                onPressed:
                    card.isLocked ? null : () => context.go(RouteNames.topUp),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'QR Kod ile Öde',
                variant: AppButtonVariant.secondary,
                icon: Icons.qr_code_2_rounded,
                onPressed:
                    card.isLocked ? null : () => showQrPaymentSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'NFC Turnike Geçişi',
                variant: AppButtonVariant.tonal,
                icon: Icons.contactless_rounded,
                height: 48,
                onPressed: () => context.push(RouteNames.nfcContactlessInfo),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: card.isLocked ? 'Kart Kilidini Aç' : 'Kartı Kilitle',
                variant: card.isLocked
                    ? AppButtonVariant.tonal
                    : AppButtonVariant.danger,
                icon: card.isLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                height: 48,
                onPressed: () {
                  if (card.isLocked) {
                    _showUnlockCardSheet(card);
                  } else {
                    context.push(RouteNames.lockCardConfirm);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Başka Fiziksel Kart Eşleştir / Düzenle',
          variant: AppButtonVariant.ghost,
          icon: Icons.edit_note_rounded,
          height: 44,
          onPressed: _showPairPhysicalCardDialog,
        ),
        const SizedBox(height: 16),
        // Monthly Subscription Status Card (`Aylık Abonman Durumu`)
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showSubscriptionDetailSheet(card),
          child: Container(
            padding: const EdgeInsets.all(18),
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
                        'Aylık Abonman Durumu',
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
                    StatusPill(
                      label: '${card.subscriptionRemaining} HAK KALDI',
                      tone: StatusPillTone.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: card.subscriptionProgress,
                    minHeight: 10,
                    backgroundColor: mavi.surfaceContainerHighest,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Kullanılan: ${card.subscriptionUsed} / ${card.subscriptionTotal} Geçiş',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Yenileme: ${card.subscriptionRenewsAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Security Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mavi.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                color: scheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Güvenliğiniz için TCKN (${card.maskedTckn}) ve ulaşım kartı seri numarası (${card.fullMaskedSerial}) maskelenerek gösterilmektedir.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Authentic Istanbul Public Transit Smart Card Front Face (`_CardFrontFace`).
class _CardFrontFace extends StatelessWidget {
  const _CardFrontFace({required this.card});

  final TransitCard card;

  @override
  Widget build(BuildContext context) {
    final parts = CurrencyFormatter.splitParts(card.balance);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF001C32),
            Color(0xFF003B64),
            Color(0xFF006767),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8DD3D1).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: _BosphorusTransitCardWatermarkPainter(),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Top Civic Transit Header Bar
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'İSTANBUL ULAŞIM KARTI',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    Text(
                                      card.alias.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFA9EFED),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.contactless_rounded,
                                color: Color(0xFFA9EFED),
                                size: 15,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AKILLI KART',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Middle Row: ISO Transit Smart Chip + Live Balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Gold ISO/IEC 14443 Transit Smart Chip
                        Container(
                          width: 46,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFF6D365),
                                Color(0xFFDAA520),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            color: Color(0xFF4A3500),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              const Text(
                                'KULLANILABİLİR BAKİYE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: <Widget>[
                                  const Text(
                                    '₺',
                                    style: TextStyle(
                                      color: Color(0xFFA9EFED),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    parts.whole,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    parts.decimal,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 19,
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
                    // 16-Digit Istanbul Transit Serial Number & Holder Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '6370  34••  ••••  ${card.lastFour}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFA9EFED),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.holderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ÖN YÜZ',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (card.isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xCC001D32),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'KART KİLİTLENDİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Personalized Istanbul Public Transit Card Back Face (`_CardBackFace`) —
/// Citizen Photo ID, Masked TCKN, Card Serial UID, and ALO 153 Civic Notice
/// (NO credit-card magnetic stripe or CVV!).
class _CardBackFace extends StatelessWidget {
  const _CardBackFace({required this.card});

  final TransitCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            Color(0xFF0A253B),
            Color(0xFF0F3854),
            Color(0xFF004F52),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8DD3D1).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Official Top Civic Banner (Instead of a credit card magnetic stripe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFFA9EFED),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'KİŞİSELLEŞTİRİLMİŞ İSTANBUL ULAŞIM KARTI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'ALO 153',
                  style: TextStyle(
                    color: Color(0xFFA9EFED),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Citizen Portrait Frame + Personal Transit Credentials + QR Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Citizen Portrait Box (Vesikalık Fotoğraf Alanı)
              Container(
                width: 66,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFF002642),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFA9EFED),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_rounded,
                      color: Color(0xFFA9EFED),
                      size: 38,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'FOTOĞRAF',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Citizen Identity Fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'KART SAHİBİ AD SOYAD',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      card.holderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'T.C. KİMLİK NO & KART SERİ UID',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'TCKN: ${card.maskedTckn}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA9EFED),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'UID: ${card.fullMaskedSerial} • VİZE: 2030',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Turnstile Verification DataMatrix
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 46,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Bu kart kişiye özeldir. Bulunması halinde ALO 153 veya Biletmatik noktasına teslim ediniz.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'ARKA YÜZ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _BosphorusTransitCardWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePaint = Paint()
      ..color = const Color(0xFF8DD3D1).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (var i = 0; i < 4; i++) {
      final dy = h * (0.48 + i * 0.11);
      final path = Path()
        ..moveTo(0, dy)
        ..cubicTo(w * 0.28, dy - 18, w * 0.62, dy + 22, w, dy - 10);
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
