import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';

/// Screen 6 (`6._kay_t_ol`): Sign-Up screen with full validation, live password
/// strength meter, KVKK consent modal, and transition to SMS OTP verification.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passwordController.text;
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(signUpUseCaseProvider)(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      acceptedTerms: _acceptedTerms,
      phoneNumber: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      onFailure: (failure) {
        setState(() => _errorMessage = failure.message);
      },
      onSuccess: (user) {
        ref.read(currentUserControllerProvider.notifier).setUser(user);
        ref.read(transitCardControllerProvider.notifier).refresh();
        ref.read(transactionsControllerProvider.notifier).refresh();
        context.go(RouteNames.authOtp);
      },
    );
  }

  void _showKvkkDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanım Koşulları ve KVKK Aydınlatma Metni'),
        content: const SingleChildScrollView(
          child: Text(
            '6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında; '
            'MaviHat İstanbul Ulaşım Cüzdanı prototip uygulamasında TCKN ve '
            'ödeme kartı bilgileriniz maskelenerek korunur. Ham kart numarası '
            '(PAN) ve CVV verileri hiçbir zaman yerel veya bulut veritabanında '
            'saklanmaz.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Okudum, Onaylıyorum'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final strength = _passwordStrength;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Yeni Hesap Oluştur',
                showBackButton: true,
                onBackPressed: () => context.go(RouteNames.signIn),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'İstanbul ulaşım kartlarını tek hesapta birleştir.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      label: 'Ad Soyad',
                      controller: _nameController,
                      hintText: 'Örn: Shahd Mohamed Kassem',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'E-Posta Adresi',
                      controller: _emailController,
                      hintText: 'ornek@mavihat.istanbul',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Cep Telefonu (SMS Doğrulama İçin)',
                      controller: _phoneController,
                      hintText: '+90 5XX XXX XX XX',
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Şifre (En az 8 karakter)',
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 4-segment Password Strength Indicator
                    Row(
                      children: List<Widget>.generate(4, (i) {
                        final active = i < strength;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                            height: 5,
                            decoration: BoxDecoration(
                              color: active
                                  ? scheme.secondary
                                  : mavi.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Şifre Tekrar',
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_reset_rounded,
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) {
                              setState(() => _acceptedTerms = v ?? false);
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _showKvkkDialog,
                              child: const Text(
                                'Kullanım Koşulları ve KVKK Aydınlatma Metnini okudum, kabul ediyorum.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Hesap Oluştur ve Doğrula',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'Zaten hesabın var mı?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(RouteNames.signIn),
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
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

