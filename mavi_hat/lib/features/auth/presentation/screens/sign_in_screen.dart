import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/mavihat_logo.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 5 (`5._giri_yap`): Sign-In screen with validation, password
/// visibility toggle, and password reset dialog. All fields start empty so the
/// user enters credentials manually.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(signInUseCaseProvider)(
      emailOrPhone: _emailController.text,
      password: _passwordController.text,
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
        context.go(RouteNames.home);
      },
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Şifre Sıfırlama Bağlantısı'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Kayıtlı e-posta adresinize şifre yenileme bağlantısı gönderilecektir.',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'E-Posta Adresi',
                    controller: resetEmailController,
                    errorText: dialogError,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final res = await ref.read(resetPasswordUseCaseProvider)(
                      email: resetEmailController.text,
                    );
                    res.fold(
                      onFailure: (f) {
                        setDialogState(() => dialogError = f.message);
                      },
                      onSuccess: (_) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${resetEmailController.text.trim()} adresine sıfırlama bağlantısı gönderildi (Prototip).',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
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
                showBackButton: true,
                onBackPressed: () => context.go(RouteNames.onboarding),
                trailing: const StatusPill(
                  label: 'GÜVENLİ GİRİŞ',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 12),
                    const MaviHatLogo(size: 58, showBadge: true),
                    const SizedBox(height: 16),
                    Text(
                      'Tekrar hoş geldin.',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MaviHat İstanbul ulaşım cüzdanına erişmek için bilgilerini gir.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline_rounded,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      label: 'E-Posta veya Telefon Numarası',
                      controller: _emailController,
                      hintText: 'ornek@mavihat.istanbul',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Şifre',
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        tooltip:
                            _obscurePassword ? 'Şifreyi Göster' : 'Şifreyi Gizle',
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Şifremi Unuttum?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Giriş Yap',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSignIn,
                    ),
                    const SizedBox(height: 14),
                    // Reference info box (no auto-fill; user enters credentials manually)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Örnek Hesap Bilgisi (Kendiniz girin):\nE-posta: shahd.kassem@mavihat.istanbul\nŞifre: Demo1234!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'Henüz MaviHat hesabın yok mu?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(RouteNames.signUp),
                          child: const Text(
                            'Kayıt Ol',
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
