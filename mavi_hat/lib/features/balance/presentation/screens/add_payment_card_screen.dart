import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 16 (`16._yeni_kart_ekle`): Add Payment Card sandbox screen with live
/// card visual preview and tokenization (never stores raw PAN or CVV).
class AddPaymentCardScreen extends ConsumerStatefulWidget {
  const AddPaymentCardScreen({super.key});

  @override
  ConsumerState<AddPaymentCardScreen> createState() =>
      _AddPaymentCardScreenState();
}

class _AddPaymentCardScreenState extends ConsumerState<AddPaymentCardScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _saveCard = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _submitCard() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final res = await ref.read(paymentMethodsControllerProvider.notifier).addCard(
          rawCardNumber: _numberController.text,
          cardholderName: _holderController.text,
          expiryInput: _expiryController.text,
          cvv: _cvvController.text,
          saveForFuture: _saveCard,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    res.fold(
      onFailure: (f) => setState(() => _errorMessage = f.message),
      onSuccess: (method) {
        ref
            .read(topUpDraftControllerProvider.notifier)
            .setPaymentMethod(method.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${method.maskedDisplay} tokenize edilerek güvenle eklendi.',
            ),
          ),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Yeni Kart Ekle',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'SANDBOX TOKEN',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Live Card Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Icon(
                                Icons.sim_card_rounded,
                                color: Color(0xFFA9EFED),
                                size: 28,
                              ),
                              Text(
                                'TROY / VISA / MC',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            DataMasker.maskPaymentPan(_numberController.text),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _holderController.text.isEmpty
                                      ? 'AD SOYAD'
                                      : _holderController.text.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                _expiryController.text.isEmpty
                                    ? 'AA/YY'
                                    : _expiryController.text,
                                style: const TextStyle(
                                  color: Color(0xFFA9EFED),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_errorMessage != null) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    AppTextField(
                      label: 'Kart Numarası (16 Hane)',
                      controller: _numberController,
                      hintText: '9792 0000 0000 4821',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.credit_card_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Kart Üzerindeki Ad Soyad',
                      controller: _holderController,
                      hintText: 'SHAHD MOHAMED KASSEM',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppTextField(
                            label: 'Son Kullanma (AA/YY)',
                            controller: _expiryController,
                            hintText: '09/29',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'CVV Güvenlik Kodu',
                            controller: _cvvController,
                            hintText: '123',
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            suffix: IconButton(
                              tooltip: 'CVV Nedir?',
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('CVV Güvenlik Kodu'),
                                    content: const Text(
                                      'Kartınızın arka yüzündeki 3 haneli güvenlik kodudur. Güvenlik kuralları gereği CVV hiçbir zaman kaydedilmez.',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('Tamam'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.help_outline_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _saveCard,
                          onChanged: (v) =>
                              setState(() => _saveCard = v ?? true),
                          title: const Text(
                            'Sonraki yüklemelerim için tokenize olarak kaydet',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Ham kart numarası ve CVV kesinlikle saklanmaz; yalnızca son 4 hane ve token referansı tutulur.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Kartı Doğrula ve Kaydet',
                      icon: Icons.lock_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _submitCard,
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

