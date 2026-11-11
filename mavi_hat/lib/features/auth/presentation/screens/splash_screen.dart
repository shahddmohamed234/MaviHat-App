import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/mavihat_logo.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 1 (`1._splash_screen`): Brand launch screen with custom Bosphorus
/// `MaviHatLogo` emblem and direct navigation into Onboarding, Sign-In, or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    final prefs = ref.read(preferencesControllerProvider);
    final user = ref.read(currentUserControllerProvider);
    if (!prefs.onboardingCompleted) {
      context.go(RouteNames.onboarding);
    } else if (user == null) {
      context.go(RouteNames.signIn);
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Flexible(
                          child: StatusPill(
                            label: 'İSTANBUL BÜYÜKŞEHİR ULAŞIM',
                            tone: StatusPillTone.navy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: StatusPill(
                            label: 'MAVİHAT v2.4',
                            tone: StatusPillTone.teal,
                            showDot: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: const MaviHatLogo(
                            size: 120,
                            showBadge: true,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'MaviHat',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'İSTANBUL AKILLI ULAŞIM CÜZDANI',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.secondary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'İstanbul’da yolun hep açık.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Vapur, Metro, Marmaray, Metrobüs ve İETT yolculukların için fiziksel kart eşleştirme, NFC temassız geçiş ve dinamik QR ödeme tek uygulamada.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: mavi.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.contactless_rounded,
                                color: scheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'NFC Turnike • 2 Dk Dinamik QR • Anında Dolum',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppButton(
                          label: 'Uygulamaya Başla',
                          trailingIcon: Icons.arrow_forward_rounded,
                          onPressed: _navigateNext,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: <Widget>[
                            TextButton(
                              onPressed: () =>
                                  context.go(RouteNames.onboarding),
                              child: const Text('Tanıtımı İncele'),
                            ),
                            const Text('•'),
                            TextButton(
                              onPressed: () => context.go(RouteNames.signIn),
                              child: const Text('Giriş Yap'),
                            ),
                            const Text('•'),
                            TextButton(
                              onPressed: () => context.go(RouteNames.signUp),
                              child: const Text('Kayıt Ol'),
                            ),
                          ],
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
