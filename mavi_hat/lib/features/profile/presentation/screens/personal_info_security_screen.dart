import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 25 (`25._ki_isel_bilgiler_g_venlik`): Personal Info & Security screen
/// with editable profile form (`UpdateProfile`), password change dialog
/// (`ChangePassword`), and security switches (`2FA`, `Biometric`).
class PersonalInfoSecurityScreen extends ConsumerStatefulWidget {
  const PersonalInfoSecurityScreen({super.key});

  @override
  ConsumerState<PersonalInfoSecurityScreen> createState() =>
      _PersonalInfoSecurityScreenState();
}

class _PersonalInfoSecurityScreenState
    extends ConsumerState<PersonalInfoSecurityScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserControllerProvider);
    _nameController = TextEditingController(
      text: user?.displayName ?? 'Shahd Mohamed Kassem',
    );
    _emailController = TextEditingController(
      text: user?.email ?? 'shahd.kassem@mavihat.istanbul',
    );
    _phoneController = TextEditingController(
      text: user?.phoneNumber ?? '+90 532 418 90 42',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final res = await ref.read(updateProfileUseCaseProvider)(
      displayName: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    res.fold(
      onFailure: (f) => setState(() => _errorMessage = f.message),
      onSuccess: (updatedUser) {
        ref.read(currentUserControllerProvider.notifier).setUser(updatedUser);
        ref.read(transitCardControllerProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişisel bilgileriniz başarıyla güncellendi.'),
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Şifre Değiştir'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppTextField(
                      label: 'Mevcut Şifre',
                      controller: currentCtrl,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Yeni Şifre (En az 8 karakter)',
                      controller: newCtrl,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Yeni Şifre Tekrar',
                      controller: confirmCtrl,
                      errorText: dialogError,
                      obscureText: true,
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
                    final res = await ref.read(changePasswordUseCaseProvider)(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                      confirmPassword: confirmCtrl.text,
                    );
                    res.fold(
                      onFailure: (f) =>
                          setDialogState(() => dialogError = f.message),
                      onSuccess: (_) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifreniz başarıyla güncellendi.'),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Şifreyi Güncelle'),
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
    final user = ref.watch(currentUserControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Kişisel Bilgiler & Güvenlik',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'KVKK KORUMALI',
                  tone: StatusPillTone.teal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    AppTextField(
                      label: 'Ad Soyad',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'E-Posta Adresi',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Cep Telefonu',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    // Masked TCKN Read-Only Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.badge_outlined, color: scheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'T.C. Kimlik Numarası (Maskeli)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  user?.tcknMasked ?? '*******1234',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const StatusPill(
                            label: 'DOĞRULANDI',
                            tone: StatusPillTone.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Değişiklikleri Kaydet',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GÜVENLİK AYARLARI',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            title: const Text(
                              'Biyometrik Giriş (Face ID / Parmak İzi)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Uygulama açılışında biyometrik doğrulama kullan',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: prefs.biometricEnabled,
                            onChanged: (val) {
                              ref
                                  .read(preferencesControllerProvider.notifier)
                                  .updatePreferences(
                                    prefs.copyWith(biometricEnabled: val),
                                  );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'İki Аşamalı SMS Doğrulama (2FA)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Yeni cihaz girişlerinde ve kart kilidi işlemlerinde SMS iste',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: prefs.twoFactorEnabled,
                            onChanged: (val) {
                              ref
                                  .read(preferencesControllerProvider.notifier)
                                  .updatePreferences(
                                    prefs.copyWith(twoFactorEnabled: val),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Hesap Şifresini Değiştir',
                      variant: AppButtonVariant.tonal,
                      icon: Icons.key_rounded,
                      onPressed: _showChangePasswordDialog,
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

