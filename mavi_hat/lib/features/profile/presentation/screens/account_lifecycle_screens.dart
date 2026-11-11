import 'package:flutter/material.dart';
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

/// Screen 29 (`29._k_yap_onay`): Logout Confirmation screen executing
/// `SignOut` use case and returning to `SignInScreen`.
class LogoutConfirmScreen extends ConsumerStatefulWidget {
  const LogoutConfirmScreen({super.key});

  @override
  ConsumerState<LogoutConfirmScreen> createState() =>
      _LogoutConfirmScreenState();
}

class _LogoutConfirmScreenState extends ConsumerState<LogoutConfirmScreen> {
  bool _isSigningOut = false;

  Future<void> _confirmSignOut() async {
    setState(() => _isSigningOut = true);
    await ref.read(signOutUseCaseProvider)();
    if (!mounted) return;
    ref.read(currentUserControllerProvider.notifier).setUser(null);
    context.go(RouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final user = ref.watch(currentUserControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    MaviHatHeader(
                      title: 'Çıkış Yap',
                      showBackButton: true,
                      onBackPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: mavi.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            size: 38,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Oturumu Kapatmak İstiyor Musunuz?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${user?.displayName ?? 'Shahd Mohamed Kassem'} hesabınızdan çıkış yaptığınızda kart bakiyeniz ve kayıtlı tercihleriniz korunur. Tekrar giriş yaparak cüzdanınıza erişebilirsiniz.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppButton(
                          label: 'Evet, Çıkış Yap',
                          variant: AppButtonVariant.danger,
                          icon: Icons.logout_rounded,
                          isLoading: _isSigningOut,
                          onPressed: _confirmSignOut,
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Vazgeç ve Oturumu Koru',
                          variant: AppButtonVariant.tonal,
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Screen 30 (`30._hesab_sil_onay`): Delete Account Confirmation screen
/// requiring checkbox consent + typing `HESABIMI SİL` before executing
/// `DeleteAccount` use case.
class DeleteAccountConfirmScreen extends ConsumerStatefulWidget {
  const DeleteAccountConfirmScreen({super.key});

  @override
  ConsumerState<DeleteAccountConfirmScreen> createState() =>
      _DeleteAccountConfirmScreenState();
}

class _DeleteAccountConfirmScreenState
    extends ConsumerState<DeleteAccountConfirmScreen> {
  final TextEditingController _confirmTextController = TextEditingController();
  bool _acknowledged = false;
  bool _isDeleting = false;
  String? _errorText;

  @override
  void dispose() {
    _confirmTextController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });

    final res = await ref.read(deleteAccountUseCaseProvider)(
      confirmationText: _confirmTextController.text,
      acknowledgedConsequences: _acknowledged,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    res.fold(
      onFailure: (f) => setState(() => _errorText = f.message),
      onSuccess: (_) {
        ref.read(currentUserControllerProvider.notifier).setUser(null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hesabınız ve yerel kullanıcı verileriniz kalıcı olarak silindi.',
            ),
          ),
        );
        context.go(RouteNames.onboarding);
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
                title: 'Hesabı Kalıcı Olarak Sil',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'GERİ ALINAMAZ',
                  tone: StatusPillTone.danger,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                                Icons.warning_amber_rounded,
                                color: scheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dikkat: Bu İşlem Geri Alınamaz',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Eşleştirilmiş dijital ulaşım kartı kayıtlarınız silinir.\n'
                            '• Kayıtlı ödeme yöntemi tokenlarınız kaldırılır.\n'
                            '• İşlem geçmişi ve destek talepleriniz sıfırlanır.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _acknowledged,
                          onChanged: (v) {
                            setState(() => _acknowledged = v ?? false);
                          },
                          title: const Text(
                            'Hesabımın kalıcı olarak silineceğini ve verilerimin sıfırlanacağını onaylıyorum.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Onaylamak için kutuya "HESABIMI SİL" yazın',
                      controller: _confirmTextController,
                      hintText: 'HESABIMI SİL',
                      errorText: _errorText,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Hesabımı Kalıcı Olarak Sil',
                      variant: AppButtonVariant.danger,
                      icon: Icons.delete_forever_rounded,
                      isLoading: _isDeleting,
                      onPressed: _handleDeleteAccount,
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

/// Screen 31 (`31._ba_lant_yok_evrim_d`): Offline / No Connection view showing
/// cached Hive CE balance with `lastSyncedAt` timestamp and retry action.
class OfflineStatusScreen extends ConsumerWidget {
  const OfflineStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final card = ref.watch(transitCardControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: <Widget>[
              MaviHatHeader(
                title: 'Çevrim Dışı Görünüm',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: const StatusPill(
                  label: 'ÖNBELLEK MODU',
                  tone: StatusPillTone.terracotta,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: mavi.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 38,
                        color: mavi.onTertiaryFixed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'İnternet Bağlantısı Olmadan Kart Bilgileriniz',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aşağıdaki bakiye bilgisi cihazınızdaki yerel Hive CE önbelleğinden okunmuştur. Son senkronizasyon sonrası turnike geçişleri bağlantınız geldiğinde güncellenir.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  card.alias,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                card.maskedNumber,
                                style: const TextStyle(
                                  color: Color(0xFFA9EFED),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'SON BİLİNEN ÖNBELLEK BAKİYESİ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatTl(card.balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Son Senkronizasyon: Bugün 18:42 • ${card.lastStationName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Bağlantıyı Yeniden Dene ve Senkronize Et',
                      icon: Icons.sync_rounded,
                      onPressed: () {
                        ref
                            .read(transitCardControllerProvider.notifier)
                            .refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kart verileri senkronize edildi. Çevrim içi görünüme dönülüyor.',
                            ),
                          ),
                        );
                        context.go(RouteNames.home);
                      },
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

