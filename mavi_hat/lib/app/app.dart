import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../features/profile/domain/entities/user_preferences.dart';
import 'di/providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Custom scroll behavior enabling mouse drag and MacBook trackpad scrolling on
/// macOS & desktop alongside touch gestures on mobile.
class MaviHatScrollBehavior extends MaterialScrollBehavior {
  const MaviHatScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Root MaviHat application widget binding theme mode, high-contrast mode,
/// localization (`tr`), macOS/desktop scroll & responsive layout, and [GoRouter].
class MaviHatApp extends ConsumerWidget {
  const MaviHatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesControllerProvider);
    final router = ref.watch(appRouterProvider);

    final themeMode = switch (prefs.themeMode) {
      AppThemeModePreference.light => ThemeMode.light,
      AppThemeModePreference.dark => ThemeMode.dark,
      AppThemeModePreference.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'MaviHat • İstanbul Ulaşım',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaviHatScrollBehavior(),
      theme: AppTheme.light(highContrast: prefs.highContrast),
      darkTheme: AppTheme.dark(highContrast: prefs.highContrast),
      themeMode: themeMode,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final width = MediaQuery.sizeOf(context).width;
        if (width <= 600) {
          return child;
        }
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}

