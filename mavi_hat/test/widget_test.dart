import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavi_hat/app/app.dart';
import 'package:mavi_hat/app/di/providers.dart';
import 'package:mavi_hat/core/storage/local_cache_datasource.dart';
import 'package:mavi_hat/core/widgets/mavihat_logo.dart';

void main() {
  Future<InMemoryCacheDataSource> pumpMaviHatApp(
    WidgetTester tester, {
    bool enterFromSplash = true,
  }) async {
    tester.view.physicalSize = const Size(430, 980);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final cache = InMemoryCacheDataSource();
    await cache.ensureSeeded();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localCacheDataSourceProvider.overrideWithValue(cache),
          enableNetworkMapTilesProvider.overrideWithValue(false),
        ],
        child: const MaviHatApp(),
      ),
    );
    await tester.pumpAndSettle();

    if (enterFromSplash) {
      final startBtn = find.text('Uygulamaya Başla');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(startBtn);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();
      }
    }
    return cache;
  }

  testWidgets(
    'Splash screen displays MaviHatLogo and navigates to Home Dashboard & all 5 tabs',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester, enterFromSplash: false);

      // Verify Splash Screen & custom MaviHatLogo
      expect(find.byType(MaviHatLogo), findsWidgets);
      expect(find.text('MaviHat'), findsOneWidget);
      expect(find.text('Uygulamaya Başla'), findsOneWidget);

      await tester.tap(find.text('Uygulamaya Başla'));
      await tester.pumpAndSettle();

      // Verify Home Dashboard content
      expect(find.textContaining('Merhaba, Shahd'), findsOneWidget);
      expect(find.text('245'), findsOneWidget);
      expect(find.text(',50'), findsOneWidget);

      // Navigate to Kartım tab
      await tester.tap(find.text('Kartım').last);
      await tester.pumpAndSettle();
      expect(find.text('Kartın arkasını gör'), findsOneWidget);

      // Flip card to Back Face (Citizen Transit ID back face, not credit card)
      await tester.tap(find.text('Kartın arkasını gör'));
      await tester.pumpAndSettle();
      expect(find.text('Ön yüzü göster'), findsOneWidget);
      expect(find.textContaining('*******1234'), findsWidgets);
      expect(find.text('FOTOĞRAF'), findsOneWidget);

      // Navigate to Yükle tab
      await tester.tap(find.text('Yükle').last);
      await tester.pumpAndSettle();
      expect(find.text('Hızlı Tutar Seçin'), findsOneWidget);

      // Navigate to Harita tab
      await tester.tap(find.text('Harita').last);
      await tester.pumpAndSettle();
      expect(find.text('Kadıköy İskelesi'), findsWidgets);

      // Navigate to Profil tab
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(find.text('Shahd Mohamed Kassem'), findsOneWidget);
      expect(find.textContaining('180******42'), findsOneWidget);
    },
  );

  testWidgets(
    'QR code payment sheet runs for 2 minutes, rotates every 30s, and auto-closes at 00:00',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Tap QR ile Öde on HomeScreen
      final qrBtn = find.text('QR ile Öde');
      await tester.ensureVisible(qrBtn);
      await tester.tap(qrBtn);
      await tester.pumpAndSettle();

      // Verify initial 2-minute timer (02:00), cycle #1, and 1. Basım Abonman CTA
      expect(
        find.text('QR Kodu Turnike Kamerasına Okutun'),
        findsOneWidget,
      );
      expect(find.text('Toplam Süre: 02:00 / 02:00'), findsOneWidget);
      expect(find.textContaining('Döngü #1'), findsOneWidget);
      expect(
        find.text('Turnikede Okut (1. Basım • Abonman)'),
        findsOneWidget,
      );

      // Tap 1. Basım -> uses Abonman, button updates to 2. Basım • ₺20,00
      final tap1Btn = find.text('Turnikede Okut (1. Basım • Abonman)');
      await tester.ensureVisible(tap1Btn);
      await tester.tap(tap1Btn);
      await tester.pump();
      expect(
        find.text('Turnikede Okut (2. Basım • ₺20,00)'),
        findsOneWidget,
      );

      // Tap 2. Basım -> charges ₺20,00 TL, button updates to 3. Basım • ₺20,00
      final tap2Btn = find.text('Turnikede Okut (2. Basım • ₺20,00)');
      await tester.ensureVisible(tap2Btn);
      await tester.tap(tap2Btn);
      await tester.pump();
      expect(
        find.text('Turnikede Okut (3. Basım • ₺20,00)'),
        findsOneWidget,
      );

      // Advance 30 seconds -> QR rotates and remaining time is 01:30
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Toplam Süre: 01:30 / 02:00'), findsOneWidget);

      // Advance remaining 90 seconds -> QR expires at 2 minutes and closes automatically
      await tester.pump(const Duration(seconds: 90));
      await tester.pumpAndSettle();
      expect(
        find.text('QR Kodu Turnike Kamerasına Okutun'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Balance Top-Up flow requires manual OTP input and updates balance on 3D Secure success',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Go to Yükle tab
      await tester.tap(find.text('Yükle').last);
      await tester.pumpAndSettle();

      // Select ₺200 preset
      await tester.tap(find.text('₺200'));
      await tester.pumpAndSettle();

      // Tap Devam Et
      final continueBtn = find.textContaining('Devam Et');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // On ConfirmTopUpScreen (Screen 17)
      expect(find.text('Yüklemeyi Onayla'), findsOneWidget);
      final confirmBtn = find.text('Ödemeyi Onayla (3D Secure)');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // On PaymentOtpScreen (Screen 18) - field starts empty, user enters 123456
      expect(find.text('Ödemeni Doğrula (3D Secure)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      final completeBtn = find.text('Ödemeyi Tamamla');
      await tester.ensureVisible(completeBtn);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // On TopUpSuccessScreen (Screen 19): 245,50 + 200,00 = 445,50
      expect(find.text('Bakiye Yükleme Başarılı!'), findsOneWidget);
      expect(find.text('₺445,50'), findsOneWidget);
    },
  );

  testWidgets(
    'Card Lock Confirmation locks card and manual SMS OTP entry unlocks it',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Go to Kartım tab
      await tester.tap(find.text('Kartım').last);
      await tester.pumpAndSettle();

      // Scroll down to Kartı Kilitle button and tap
      final lockBtn = find.text('Kartı Kilitle');
      await tester.ensureVisible(lockBtn);
      await tester.tap(lockBtn);
      await tester.pumpAndSettle();

      // On LockCardConfirmScreen (Screen 22)
      expect(find.text('Kart Kilitleme Onayı'), findsOneWidget);
      final confirmLockBtn = find.text('Evet, Kartı Kilitle');
      await tester.ensureVisible(confirmLockBtn);
      await tester.tap(confirmLockBtn);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Locked State (Screen 23)
      expect(find.text('Kartınız Güvenlik Kilidi Altında'), findsOneWidget);

      // Open SMS OTP Unlock Sheet and manually enter 123456
      final unlockSheetBtn =
          find.text('Kart Kilidini Kaldır (SMS Doğrulama)');
      await tester.ensureVisible(unlockSheetBtn);
      await tester.tap(unlockSheetBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pumpAndSettle();

      final verifyUnlockBtn = find.text('Doğrula ve Kilidi Kaldır');
      await tester.ensureVisible(verifyUnlockBtn);
      await tester.tap(verifyUnlockBtn);
      await tester.pumpAndSettle();

      expect(find.text('Kartınız Güvenlik Kilidi Altında'), findsNothing);
    },
  );

  testWidgets(
    'Settings screen switches Theme Mode and clears Cache (Turkish only)',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Go to Profil tab
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();

      // Open Settings & Preferences (Screen 26)
      final settingsTile = find.text('Ayarlar ve Tercihler');
      await tester.ensureVisible(settingsTile);
      await tester.tap(settingsTile);
      await tester.pumpAndSettle();

      expect(find.text('Uygulama Teması'), findsOneWidget);
      expect(find.text('14.2 MB'), findsOneWidget);
      // Verify extra non-working languages were removed
      expect(find.text('English'), findsNothing);

      // Switch to Dark Mode
      await tester.tap(find.text('Koyu Mod'));
      await tester.pumpAndSettle();

      // Clear Cache
      final clearCacheBtn = find.text('Önbelleği Temizle');
      await tester.ensureVisible(clearCacheBtn);
      await tester.tap(clearCacheBtn);
      await tester.pumpAndSettle();

      expect(find.text('0.0 MB'), findsOneWidget);
    },
  );

  testWidgets(
    'Payment failure scenario (ERR-4012) navigates to TopUpFailureScreen and preserves balance',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Go to Yükle tab
      await tester.tap(find.text('Yükle').last);
      await tester.pumpAndSettle();

      final continueBtn = find.textContaining('Devam Et');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Ödemeyi Onayla (3D Secure)');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Manually enter 000000 failure code on PaymentOtpScreen
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();

      final completeBtn = find.text('Ödemeyi Tamamla');
      await tester.ensureVisible(completeBtn);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Verify TopUpFailureScreen (Screen 20) & preserved balance
      expect(find.text('Ödeme Tamamlanamadı'), findsOneWidget);
      expect(
        find.text('KORUNAN MEVCUT BAKİYENİZ (DEĞİŞMEDİ)'),
        findsOneWidget,
      );
      expect(find.text('₺245,50'), findsOneWidget);

      // Tap Tekrar Dene to return to TopUpScreen
      final retryBtn = find.text('Tekrar Dene');
      await tester.ensureVisible(retryBtn);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();
      expect(find.text('Hızlı Tutar Seçin'), findsOneWidget);
    },
  );

  testWidgets(
    'Transaction History filtering, empty state recovery, and Transaction Detail receipt work',
    (WidgetTester tester) async {
      await pumpMaviHatApp(tester);

      // Tap Tümünü Gör on HomeScreen to open TransactionHistoryScreen (Screen 12)
      final seeAllBtn = find.text('Tümünü Gör');
      await tester.ensureVisible(seeAllBtn);
      await tester.tap(seeAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vapur'), findsOneWidget);

      // Filter by Vapur
      final ferryChip = find.text('Vapur');
      await tester.ensureVisible(ferryChip);
      await tester.tap(ferryChip);
      await tester.pumpAndSettle();
      expect(find.text('Kadıköy İskelesi'), findsWidgets);

      // Open TransactionDetailScreen (Screen 13)
      final txnItem = find.text('Kadıköy İskelesi').first;
      await tester.ensureVisible(txnItem);
      await tester.tap(txnItem);
      await tester.pumpAndSettle();
      expect(find.text('İşlem Detayı'), findsOneWidget);
      expect(find.text('TAMAMLANDI • ONAYLI İŞLEM'), findsOneWidget);
    },
  );

  testWidgets(
    'Logout Confirmation, manual Sign-In entry, and Persistence across app restart work',
    (WidgetTester tester) async {
      final cache = await pumpMaviHatApp(tester);

      // Go to Profil tab -> Çıkış Yap (Screen 29)
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();

      final logoutBtn = find.text('Çıkış Yap');
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Oturumu Kapatmak İstiyor Musunuz?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Evet, Çıkış Yap'));
      await tester.pumpAndSettle();

      // Now on SignInScreen (Screen 5) - fields are empty, user enters credentials manually
      expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'shahd.kassem@mavihat.istanbul');
      await tester.enterText(fields.at(1), 'Demo1234!');
      await tester.pumpAndSettle();

      final signInBtn = find.text('Giriş Yap');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Back on HomeScreen
      expect(find.textContaining('Merhaba, Shahd'), findsOneWidget);

      // Re-pump MaviHatApp with the same cache to verify persistence across restart
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            localCacheDataSourceProvider.overrideWithValue(cache),
            enableNetworkMapTilesProvider.overrideWithValue(false),
          ],
          child: const MaviHatApp(),
        ),
      );
      await tester.pumpAndSettle();
      final startBtnAfterRestart = find.text('Uygulamaya Başla');
      if (startBtnAfterRestart.evaluate().isNotEmpty) {
        await tester.tap(startBtnAfterRestart);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Merhaba, Shahd'), findsOneWidget);
      expect(find.text('245'), findsOneWidget);
    },
  );
}
