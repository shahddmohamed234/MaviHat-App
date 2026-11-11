import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screens 2, 3, and 4:
/// - `2._onboarding_kart_n_hep_yan_nda` ("Kartın hep yanında")
/// - `3._onboarding_yolculuklar_n_kontrol_alt_nda` ("Yolculukların kontrol altında")
/// - `4._onboarding_son_i_lem_noktan_ke_fet` ("Son işlem noktanı keşfet")
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<_OnboardingSlideData> _slides = <_OnboardingSlideData>[
    _OnboardingSlideData(
      badge: 'DİJİTAL ULAŞIM KARTI',
      title: 'Kartın hep yanında',
      description:
          'İstanbul ulaşım kartını dijital cüzdanında taşı, bakiyeni ve aylık abonman haklarını saniyeler içinde görüntüle.',
      icon: Icons.credit_card_rounded,
      highlightLabel: 'MaviHat •••• 4821 • ₺245,50',
    ),
    _OnboardingSlideData(
      badge: 'ANINDA BAKİYE & HAREKETLER',
      title: 'Yolculukların kontrol altında',
      description:
          'Vapur, Metro ve Otobüs harcamalarını detaylı incele; komisyonsuz hızlı bakiye yükleme ile turnikede zaman kaybetme.',
      icon: Icons.insights_rounded,
      highlightLabel: 'Kadıköy İskelesi • -₺27,50 • Bugün 18:42',
    ),
    _OnboardingSlideData(
      badge: 'SON İŞLEM NOKTASI HARİTASI',
      title: 'Son işlem noktanı keşfet',
      description:
          'Kartının son basıldığı iskele veya metro istasyonunu harita üzerinde gör, yakınındaki dolum noktalarını kolayca bul.',
      icon: Icons.map_rounded,
      highlightLabel: 'Son İşlem Noktası: Kadıköy İskelesi (Turnike #4)',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndGo(String route) async {
    final prefs = ref.read(preferencesControllerProvider);
    await ref
        .read(preferencesControllerProvider.notifier)
        .updatePreferences(prefs.copyWith(onboardingCompleted: true));
    if (!mounted) return;
    context.go(route);
  }

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeAndGo(RouteNames.signIn);
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: <Widget>[
              // Top navigation bar (Back & Skip)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (_currentIndex > 0)
                    TextButton.icon(
                      onPressed: _prevSlide,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Geri'),
                    )
                  else
                    const SizedBox(width: 80),
                  Row(
                    children: List<Widget>.generate(_slides.length, (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: () => _completeAndGo(RouteNames.signIn),
                      child: const Text('Atla'),
                    )
                  else
                    const SizedBox(width: 80),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: AppColors.bosphorusCardGradient,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mavi.surfaceContainerLowest
                                        .withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    slide.highlightLabel,
                                    textAlign: TextAlign.center,
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
                          const SizedBox(height: 28),
                          StatusPill(
                            label: slide.badge,
                            tone: StatusPillTone.teal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (!isLast)
                AppButton(
                  label: 'Devam et',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _nextSlide,
                )
              else
                Column(
                  children: <Widget>[
                    AppButton(
                      label: 'Giriş yap',
                      icon: Icons.login_rounded,
                      onPressed: () => _completeAndGo(RouteNames.signIn),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Hesap oluştur',
                      variant: AppButtonVariant.tonal,
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () => _completeAndGo(RouteNames.signUp),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.highlightLabel,
  });

  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final String highlightLabel;
}

