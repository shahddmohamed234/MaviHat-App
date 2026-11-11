import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/balance/presentation/screens/add_payment_card_screen.dart';
import '../../features/balance/presentation/screens/payment_methods_screen.dart';
import '../../features/balance/presentation/screens/top_up_flow_screens.dart';
import '../../features/balance/presentation/screens/top_up_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/presentation/screens/account_lifecycle_screens.dart';
import '../../features/profile/presentation/screens/personal_info_security_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_preferences_screen.dart';
import '../../features/support/presentation/screens/support_screens.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/presentation/screens/transaction_history_screen.dart';
import '../../features/transit_card/presentation/screens/lock_card_confirm_screen.dart';
import '../../features/transit_card/presentation/screens/my_card_screen.dart';
import '../../features/transit_card/presentation/screens/nfc_contactless_info_screen.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

/// Provides the application's [GoRouter] configuration across all 31 screens.
/// Launches on [RouteNames.splash] so the MaviHat Splash & Logo screen is
/// always presented on startup.
final appRouterProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(initialLocation: RouteNames.splash);
});

GoRouter buildAppRouter({String initialLocation = RouteNames.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RouteNames.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RouteNames.authOtp,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      // 5-Tab Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MaviHatShellScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.myCard,
                builder: (context, state) => const MyCardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.topUp,
                builder: (context, state) => const TopUpScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.map,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes outside the bottom navigation bar
      GoRoute(
        path: RouteNames.nfcContactlessInfo,
        builder: (context, state) => const NfcContactlessInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.lockCardConfirm,
        builder: (context, state) => const LockCardConfirmScreen(),
      ),
      GoRoute(
        path: RouteNames.transactionHistory,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.transactionDetail,
        builder: (context, state) {
          final id =
              state.uri.queryParameters['id'] ?? 'txn_kadikoy_94820';
          return TransactionDetailScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: RouteNames.paymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: RouteNames.addPaymentCard,
        builder: (context, state) => const AddPaymentCardScreen(),
      ),
      GoRoute(
        path: RouteNames.confirmTopUp,
        builder: (context, state) => const ConfirmTopUpScreen(),
      ),
      GoRoute(
        path: RouteNames.paymentOtp,
        builder: (context, state) => const PaymentOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.topUpSuccess,
        builder: (context, state) => const TopUpSuccessScreen(),
      ),
      GoRoute(
        path: RouteNames.topUpFailure,
        builder: (context, state) => const TopUpFailureScreen(),
      ),
      GoRoute(
        path: RouteNames.personalInfoSecurity,
        builder: (context, state) => const PersonalInfoSecurityScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsPreferences,
        builder: (context, state) => const SettingsPreferencesScreen(),
      ),
      GoRoute(
        path: RouteNames.helpAndFaq,
        builder: (context, state) => const HelpAndFaqScreen(),
      ),
      GoRoute(
        path: RouteNames.helpArticleDetail,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? 'art_pending_topup';
          return HelpArticleDetailScreen(articleId: id);
        },
      ),
      GoRoute(
        path: RouteNames.logoutConfirm,
        builder: (context, state) => const LogoutConfirmScreen(),
      ),
      GoRoute(
        path: RouteNames.deleteAccountConfirm,
        builder: (context, state) => const DeleteAccountConfirmScreen(),
      ),
      GoRoute(
        path: RouteNames.offlineStatus,
        builder: (context, state) => const OfflineStatusScreen(),
      ),
    ],
  );
}

/// Persistent 5-tab bottom navigation shell matching the Stitch Bosphorus
/// Civic Transit navigation bar (`Ana Sayfa`, `Kartım`, `Yükle`, `Harita`, `Profil`).
class MaviHatShellScaffold extends StatelessWidget {
  const MaviHatShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: mavi.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: mavi.primaryFixed,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: scheme.primary),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.credit_card_outlined),
              selectedIcon:
                  Icon(Icons.credit_card_rounded, color: scheme.primary),
              label: l10n.navCard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet_rounded,
                color: scheme.primary,
              ),
              label: l10n.navTopUp,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: scheme.primary),
              label: l10n.navMap,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: scheme.primary),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

