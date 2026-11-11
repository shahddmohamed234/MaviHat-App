import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 7 (`7._otp_do_rulama`): 6-digit SMS OTP verification screen with
/// countdown timer, resend action, phone edit dialog, and dev test OTP banner.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 148;
  bool _isLoading = false;
  String? _errorMessage;
  String _maskedPhone = '+90 532 ••• •• 42';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserControllerProvider);
    if (user != null) {
      _maskedPhone = DataMasker.maskPhone(user.phoneNumber);
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_otpController.text.length < 6) {
      setState(() {
        _otpController.text = '${_otpController.text}$digit';
        _errorMessage = null;
      });
    }
  }

  void _backspace() {
    if (_otpController.text.isNotEmpty) {
      setState(() {
        _otpController.text = _otpController.text
            .substring(0, _otpController.text.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _resendOtp() async {
    final user = ref.read(currentUserControllerProvider);
    final res = await ref.read(requestPhoneOtpUseCaseProvider)(
      phoneNumber: user?.phoneNumber ?? '+90 532 418 90 42',
    );
    if (!mounted) return;
    res.fold(
      onFailure: (f) => setState(() => _errorMessage = f.message),
      onSuccess: (challenge) {
        setState(() {
          _remainingSeconds = challenge.expiresInSeconds;
          _otpController.clear();
          _errorMessage = null;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yeni doğrulama kodu gönderildi (SMS Kodu: ${challenge.devTestCodeHint})',
            ),
          ),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(verifyPhoneOtpUseCaseProvider)(
      challengeId: 'otp_auth_challenge',
      code: _otpController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    res.fold(
      onFailure: (f) => setState(() => _errorMessage = f.message),
      onSuccess: (_) {
        context.go(RouteNames.home);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final code = _otpController.text;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: <Widget>[
              MaviHatHeader(
                title: 'SMS Doğrulama',
                showBackButton: true,
                onBackPressed: () => context.go(RouteNames.signIn),
                trailing: const StatusPill(
                  label: 'TEST OTP: 123456',
                  tone: StatusPillTone.terracotta,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Text(
                      'Güvenlik Kodunu Girin',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_maskedPhone numaralı telefonunuza gönderilen 6 haneli doğrulama kodunu girin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    // 6 OTP visual cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(6, (index) {
                        final char = index < code.length ? code[index] : '';
                        final isFocused = index == code.length;
                        return Container(
                          width: 48,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: mavi.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? scheme.secondary
                                  : scheme.outlineVariant,
                              width: isFocused ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            char,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'Kalan Süre: $mins:$secs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.secondary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: _resendOtp,
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
                    const SizedBox(height: 10),
                    // Interactive Keypad
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: <Widget>[
                        for (final d in <String>[
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                        ])
                          _KeypadButton(
                            label: d,
                            onTap: () => _appendDigit(d),
                          ),
                        _KeypadButton(
                          label: 'Temizle',
                          onTap: () => setState(() => _otpController.clear()),
                        ),
                        _KeypadButton(
                          label: '0',
                          onTap: () => _appendDigit('0'),
                        ),
                        _KeypadButton(
                          icon: Icons.backspace_outlined,
                          onTap: _backspace,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Doğrula ve Devam Et',
                      icon: Icons.verified_rounded,
                      isLoading: _isLoading,
                      onPressed: _verifyOtp,
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

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mavi = context.maviTheme;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: mavi.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: icon != null
              ? Icon(icon, color: scheme.primary, size: 20)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: label!.length > 1 ? 12 : 18,
                    color: scheme.primary,
                  ),
                ),
        ),
      ),
    );
  }
}

