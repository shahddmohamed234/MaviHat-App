import 'package:flutter_test/flutter_test.dart';
import 'package:mavi_hat/core/errors/failure.dart';
import 'package:mavi_hat/core/storage/cache_keys.dart';
import 'package:mavi_hat/core/storage/local_cache_datasource.dart';
import 'package:mavi_hat/core/utils/data_masker.dart';
import 'package:mavi_hat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mavi_hat/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mavi_hat/features/balance/data/repositories/balance_repository_impl.dart';
import 'package:mavi_hat/features/balance/domain/entities/balance_entities.dart';
import 'package:mavi_hat/features/balance/domain/usecases/balance_usecases.dart';
import 'package:mavi_hat/features/map/data/repositories/map_repository_impl.dart';
import 'package:mavi_hat/features/map/domain/usecases/map_usecases.dart';
import 'package:mavi_hat/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mavi_hat/features/profile/domain/entities/user_preferences.dart';
import 'package:mavi_hat/features/profile/domain/usecases/profile_usecases.dart';
import 'package:mavi_hat/features/support/data/repositories/support_repository_impl.dart';
import 'package:mavi_hat/features/support/domain/usecases/support_usecases.dart';
import 'package:mavi_hat/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mavi_hat/features/transactions/domain/entities/transit_transaction.dart';
import 'package:mavi_hat/features/transit_card/data/repositories/transit_card_repository_impl.dart';
import 'package:mavi_hat/features/transit_card/domain/entities/transit_card.dart';
import 'package:mavi_hat/features/transit_card/domain/usecases/transit_card_usecases.dart';

void main() {
  late InMemoryCacheDataSource cache;
  late AuthRepositoryImpl authRepo;
  late SandboxPhoneOtpService otpService;
  late TransitCardRepositoryImpl cardRepo;
  late PrototypeTransitCredentialService credentialService;
  late SandboxPaymentGateway paymentGateway;
  late BalanceRepositoryImpl balanceRepo;
  late TransactionRepositoryImpl txnRepo;
  late MapRepositoryImpl mapRepo;
  late PrototypeDeviceLocationService deviceLocService;
  late ProfileRepositoryImpl profileRepo;
  late PreferencesRepositoryImpl prefsRepo;
  late SupportRepositoryImpl supportRepo;

  setUp(() async {
    cache = InMemoryCacheDataSource();
    await cache.ensureSeeded();
    authRepo = AuthRepositoryImpl(cache);
    otpService = const SandboxPhoneOtpService();
    cardRepo = TransitCardRepositoryImpl(cache);
    credentialService = const PrototypeTransitCredentialService();
    paymentGateway = const SandboxPaymentGateway();
    balanceRepo = BalanceRepositoryImpl(
      cache: cache,
      paymentGateway: paymentGateway,
    );
    txnRepo = TransactionRepositoryImpl(cache);
    mapRepo = MapRepositoryImpl(cache);
    deviceLocService = const PrototypeDeviceLocationService();
    profileRepo = ProfileRepositoryImpl(cache);
    prefsRepo = PreferencesRepositoryImpl(cache);
    supportRepo = SupportRepositoryImpl(cache);
  });

  group('Security & DataMasker Tests', () {
    test('TCKN masking never exposes full 11-digit TCKN', () {
      const fullInput = '18049283142';
      final maskedCard = DataMasker.maskTckn(fullInput);
      final maskedProfile = DataMasker.maskTcknProfile(fullInput);

      expect(maskedCard, '*******3142');
      expect(maskedCard.contains(fullInput), isFalse);
      expect(maskedProfile, '180******42');
      expect(maskedProfile.contains(fullInput), isFalse);
    });

    test('Payment card tokenization never stores raw PAN or CVV in cache', () async {
      final addUseCase = AddPaymentMethod(balanceRepo);
      const rawPan = '5400111122229876';
      const rawCvv = '849';

      final result = await addUseCase(
        rawCardNumber: rawPan,
        cardholderName: 'Shahd Kassem',
        expiryInput: '10/29',
        cvv: rawCvv,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.lastFour, '9876');

      final storedList = cache.readList(CacheKeys.paymentMethods);
      for (final map in storedList) {
        expect(map.containsKey('rawPan'), isFalse);
        expect(map.containsKey('cardNumber'), isFalse);
        expect(map.containsKey('cvv'), isFalse);
        expect(map.toString().contains(rawPan), isFalse);
        expect(map.toString().contains(rawCvv), isFalse);
      }
    });
  });

  group('Top-Up Validation & Atomic Balance + Transaction Rules', () {
    test('ValidateTopUpAmount enforces min ₺1 and max ₺1000', () {
      const validator = ValidateTopUpAmount();
      expect(validator(null).isFailure, isTrue);
      expect(validator(0.99).isFailure, isTrue);
      expect(validator(1000.01).isFailure, isTrue);
      expect(validator(1.0).isSuccess, isTrue);
      expect(validator(20.0).isSuccess, isTrue);
      expect(validator(250.0).isSuccess, isTrue);
      expect(validator(1000.0).isSuccess, isTrue);
    });

    test('Successful top-up atomically increases balance and creates transaction', () async {
      final confirmUseCase = ConfirmTopUpPayment(balanceRepo);
      final initialCard = cardRepo.getActiveCardSync();
      final initialTxns = txnRepo.getTransactionsSync(cardId: initialCard.id);

      expect(initialCard.balance, 245.50);

      final result = await confirmUseCase(
        request: TopUpRequest(
          cardId: initialCard.id,
          amount: 150.0,
          paymentMethodId: 'pm_troy_4821',
          orderReference: 'MVH-TEST-1',
        ),
        otpCode: '123456',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.updatedBalance, 395.50);

      final updatedCard = cardRepo.getActiveCardSync();
      final updatedTxns = txnRepo.getTransactionsSync(cardId: initialCard.id);

      expect(updatedCard.balance, 395.50);
      expect(updatedTxns.length, initialTxns.length + 1);
      expect(updatedTxns.first.type, TransactionType.topUp);
      expect(updatedTxns.first.amount, 150.0);
    });

    test('Failed or rejected payment does NOT change balance or append transaction', () async {
      final confirmUseCase = ConfirmTopUpPayment(balanceRepo);
      final initialCard = cardRepo.getActiveCardSync();
      final initialTxns = txnRepo.getTransactionsSync(cardId: initialCard.id);

      final result = await confirmUseCase(
        request: TopUpRequest(
          cardId: initialCard.id,
          amount: 200.0,
          paymentMethodId: 'pm_troy_4821',
          orderReference: 'MVH-TEST-FAIL',
          simulateGatewayFailure: true,
        ),
        otpCode: '123456',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PaymentFailure>());
      expect(result.failureOrNull?.code, 'ERR-4012');

      final afterCard = cardRepo.getActiveCardSync();
      final afterTxns = txnRepo.getTransactionsSync(cardId: initialCard.id);
      expect(afterCard.balance, initialCard.balance);
      expect(afterTxns.length, initialTxns.length);
    });
  });

  group('Transit Card Lock, Unlock, Active NFC & Turnstile Pass Rules', () {
    test('Active card enables NFC eligibility and locked card blocks top-up & NFC', () async {
      final lockUseCase = LockTransitCard(cardRepo);
      final unlockUseCase = UnlockTransitCard(cardRepo);
      final nfcUseCase = CheckNfcEligibility(credentialService);
      final confirmTopUp = ConfirmTopUpPayment(balanceRepo);
      final passUseCase = ExecuteTurnstilePass(cardRepo);
      final loadSubUseCase = LoadSubscription(cardRepo);

      final active = cardRepo.getActiveCardSync();
      expect(active.status, CardStatus.active);
      expect(active.subscriptionRemaining, 1);

      // Cannot load Monthly Subscription while active passes remain in the same month
      final prematureSubRes = await loadSubUseCase(
        cardId: active.id,
        addedPasses: 200,
        price: 260.0,
        packageTitle: 'Tam MaviHat Aylık Abonman',
        paymentMethodLabel: 'TROY •••• 4821',
      );
      expect(prematureSubRes.isFailure, isTrue);

      final activeNfcStatus = nfcUseCase(active);
      expect(activeNfcStatus.isCardActive, isTrue);
      expect(activeNfcStatus.isProductionAvailable, isTrue);

      // 1st tap (automatic station detection) deducts the last remaining pass from Monthly Subscription
      final pass1Res = await passUseCase(
        cardId: active.id,
        fareAmount: 20.00,
        methodLabel: 'NFC Temassız',
      );
      expect(pass1Res.isSuccess, isTrue);
      expect(
        pass1Res.valueOrNull?.subscriptionUsed,
        active.subscriptionUsed + 1,
      );
      expect(pass1Res.valueOrNull?.subscriptionRemaining, 0);
      expect(pass1Res.valueOrNull?.balance, active.balance);

      // 2nd, 3rd consecutive taps automatically charge ₺20,00 TL each
      final pass2Res = await passUseCase(
        cardId: active.id,
        fareAmount: 20.00,
        methodLabel: 'NFC Temassız',
      );
      expect(pass2Res.isSuccess, isTrue);
      expect(pass2Res.valueOrNull?.balance, active.balance - 20.00);

      final pass3Res = await passUseCase(
        cardId: active.id,
        fareAmount: 20.00,
        methodLabel: 'NFC Temassız',
      );
      expect(pass3Res.isSuccess, isTrue);
      expect(pass3Res.valueOrNull?.balance, active.balance - 40.00);
      expect(
        txnRepo.getTransactionsSync(cardId: active.id).first.subtitle,
        contains('3. Basım'),
      );

      // Now that subscription passes finished (0 remaining), loading ₺260,00 Monthly Subscription (+200 passes) succeeds
      final subRes = await loadSubUseCase(
        cardId: active.id,
        addedPasses: 200,
        price: 260.0,
        packageTitle: 'Tam MaviHat Aylık Abonman',
        paymentMethodLabel: 'TROY •••• 4821',
      );
      expect(subRes.isSuccess, isTrue);
      expect(subRes.valueOrNull?.subscriptionUsed, 0);
      expect(subRes.valueOrNull?.subscriptionRemaining, 200);

      // Trying to load again in the same month while 200 passes remain is blocked
      final duplicateSubRes = await loadSubUseCase(
        cardId: active.id,
        addedPasses: 200,
        price: 260.0,
        packageTitle: 'Tam MaviHat Aylık Abonman',
        paymentMethodLabel: 'TROY •••• 4821',
      );
      expect(duplicateSubRes.isFailure, isTrue);

      final lockedRes = await lockUseCase(
        cardId: active.id,
        reportStolenTo153: true,
      );
      expect(lockedRes.isSuccess, isTrue);
      expect(lockedRes.valueOrNull?.isLocked, isTrue);

      final nfcStatus = nfcUseCase(lockedRes.valueOrNull!);
      expect(nfcStatus.isCardActive, isFalse);
      expect(nfcStatus.isProductionAvailable, isFalse);

      final topUpAttempt = await confirmTopUp(
        request: TopUpRequest(
          cardId: active.id,
          amount: 100.0,
          paymentMethodId: 'pm_troy_4821',
          orderReference: 'MVH-LOCKED',
        ),
        otpCode: '123456',
      );
      expect(topUpAttempt.isFailure, isTrue);
      expect(topUpAttempt.failureOrNull, isA<CardLockedFailure>());

      final unlockRes = await unlockUseCase(
        cardId: active.id,
        otpCode: '123456',
      );
      expect(unlockRes.isSuccess, isTrue);
      expect(unlockRes.valueOrNull?.isActive, isTrue);
    });
  });

  group('Map Last Transaction Station vs Device Location', () {
    test('LastTransactionLocation comes from latest fare transaction and is distinct from device GPS', () async {
      final lastLocUseCase = GetLastTransactionLocation(mapRepo);
      final deviceLocUseCase = GetDeviceLocation(deviceLocService);

      final lastLoc = lastLocUseCase.sync('card_mavihat_4821');
      final deviceLocRes = await deviceLocUseCase();

      expect(lastLoc.stationName, 'Kadıköy İskelesi');
      expect(lastLoc.validatorCode, contains('VLD-KDK-04'));
      expect(deviceLocRes.isSuccess, isTrue);
      expect(
        deviceLocRes.valueOrNull!.latitude != lastLoc.latitude ||
            deviceLocRes.valueOrNull!.longitude != lastLoc.longitude,
        isTrue,
      );
    });
  });

  group('Auth, New Account Zero-Card Pairing, Profile, Preferences & Support', () {
    test('SignUp starts with 0 cards (unpaired) and requires PairPhysicalCard', () async {
      final signUp = SignUp(authRepo);
      final pairCard = PairPhysicalCard(cardRepo);
      final signOut = SignOut(authRepo);
      final signIn = SignIn(authRepo);
      final verifyOtp = VerifyPhoneOtp(otpService);
      final deleteAccount = DeleteAccount(authRepo);

      final signUpRes = await signUp(
        fullName: 'Deniz Yılmaz',
        email: 'deniz@mavihat.istanbul',
        password: 'Password123!',
        confirmPassword: 'Password123!',
        acceptedTerms: true,
      );
      expect(signUpRes.isSuccess, isTrue);

      // New accounts must NOT have a pre-loaded card
      expect(cardRepo.getUserCardsSync(), isEmpty);
      expect(cardRepo.getActiveCardSync().isUnpaired, isTrue);

      // User pairs their own physical card
      final pairedRes = await pairCard(
        serialNumber: '6370 3412 8890 7741',
        alias: 'Deniz İstanbulkart',
      );
      expect(pairedRes.isSuccess, isTrue);
      expect(pairedRes.valueOrNull?.isUnpaired, isFalse);
      expect(pairedRes.valueOrNull?.balance, 0.0);
      expect(pairedRes.valueOrNull?.holderName, 'DENIZ YILMAZ');

      final otpRes = await verifyOtp(
        challengeId: 'ch_1',
        code: '123456',
      );
      expect(otpRes.isSuccess, isTrue);

      await signOut();
      expect(authRepo.getCurrentUserSync(), isNull);

      final signInRes = await signIn(
        emailOrPhone: 'deniz@mavihat.istanbul',
        password: 'Password123!',
      );
      expect(signInRes.isSuccess, isTrue);

      final delFail = await deleteAccount(
        confirmationText: 'YANLIS',
        acknowledgedConsequences: true,
      );
      expect(delFail.isFailure, isTrue);

      final delOk = await deleteAccount(
        confirmationText: 'HESABIMI SİL',
        acknowledgedConsequences: true,
      );
      expect(delOk.isSuccess, isTrue);
      expect(authRepo.getCurrentUserSync(), isNull);
    });

    test('Profile update, theme preferences, cache clear, and support bookmark persist', () async {
      final updateProfile = UpdateProfile(profileRepo);
      final updateTheme = UpdateTheme(prefsRepo);
      final clearCache = ClearAppCache(prefsRepo);
      final toggleBookmark = ToggleArticleBookmark(supportRepo);

      final profRes = await updateProfile(
        displayName: 'Shahd K.',
        email: 'shahd.kassem@mavihat.istanbul',
        phoneNumber: '+90 532 418 90 42',
      );
      expect(profRes.valueOrNull?.displayName, 'Shahd K.');

      await updateTheme(AppThemeModePreference.dark);
      final cleared = await clearCache();

      expect(cleared.valueOrNull?.themeMode, AppThemeModePreference.dark);
      expect(cleared.valueOrNull?.localeCode, 'tr');
      expect(cleared.valueOrNull?.cacheSizeMb, 0.0);

      final bookmarked = await toggleBookmark('art_pending_topup');
      expect(bookmarked.valueOrNull?.isBookmarked, isTrue);
    });
  });
}
