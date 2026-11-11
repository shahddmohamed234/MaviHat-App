import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_cache_datasource.dart';
import '../../core/utils/result.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/phone_otp_service.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/balance/data/repositories/balance_repository_impl.dart';
import '../../features/balance/domain/entities/balance_entities.dart';
import '../../features/balance/domain/repositories/balance_repository.dart';
import '../../features/balance/domain/usecases/balance_usecases.dart';
import '../../features/map/data/repositories/map_repository_impl.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../features/map/domain/usecases/map_usecases.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/entities/user_preferences.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/support_usecases.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/entities/transit_transaction.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/transaction_usecases.dart';
import '../../features/transit_card/data/repositories/transit_card_repository_impl.dart';
import '../../features/transit_card/domain/entities/transit_card.dart';
import '../../features/transit_card/domain/repositories/transit_card_repository.dart';
import '../../features/transit_card/domain/usecases/transit_card_usecases.dart';

/// Core local cache provider overridden at startup with the initialized
/// [LocalCacheDataSource] (Hive CE or in-memory test store).
final localCacheDataSourceProvider = Provider<LocalCacheDataSource>((ref) {
  final ds = InMemoryCacheDataSource();
  ds.ensureSeeded();
  return ds;
});

/// Controls whether [FlutterMap] fetches live network tiles (enabled in app,
/// overridable in widget tests so `FakeAsync` does not hang on HTTP retry timers).
final enableNetworkMapTilesProvider = Provider<bool>((ref) => true);

// ============================================================================
// REPOSITORY & SERVICE PROVIDERS
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final phoneOtpServiceProvider = Provider<PhoneOtpService>((ref) {
  return const SandboxPhoneOtpService();
});

final transitCardRepositoryProvider = Provider<TransitCardRepository>((ref) {
  return TransitCardRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final transitCredentialServiceProvider =
    Provider<TransitCredentialService>((ref) {
  return const PrototypeTransitCredentialService();
});

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return const SandboxPaymentGateway();
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepositoryImpl(
    cache: ref.watch(localCacheDataSourceProvider),
    paymentGateway: ref.watch(paymentGatewayProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return const PrototypeDeviceLocationService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(ref.watch(localCacheDataSourceProvider));
});

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

final signInUseCaseProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);
final signUpUseCaseProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);
final signOutUseCaseProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);
final resetPasswordUseCaseProvider = Provider<ResetPassword>(
  (ref) => ResetPassword(ref.watch(authRepositoryProvider)),
);
final deleteAccountUseCaseProvider = Provider<DeleteAccount>(
  (ref) => DeleteAccount(ref.watch(authRepositoryProvider)),
);
final requestPhoneOtpUseCaseProvider = Provider<RequestPhoneOtp>(
  (ref) => RequestPhoneOtp(ref.watch(phoneOtpServiceProvider)),
);
final verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtp>(
  (ref) => VerifyPhoneOtp(ref.watch(phoneOtpServiceProvider)),
);

final getTransitCardUseCaseProvider = Provider<GetTransitCard>(
  (ref) => GetTransitCard(ref.watch(transitCardRepositoryProvider)),
);
final getUserCardsUseCaseProvider = Provider<GetUserCards>(
  (ref) => GetUserCards(ref.watch(transitCardRepositoryProvider)),
);
final selectActiveCardUseCaseProvider = Provider<SelectActiveCard>(
  (ref) => SelectActiveCard(ref.watch(transitCardRepositoryProvider)),
);
final lockTransitCardUseCaseProvider = Provider<LockTransitCard>(
  (ref) => LockTransitCard(ref.watch(transitCardRepositoryProvider)),
);
final unlockTransitCardUseCaseProvider = Provider<UnlockTransitCard>(
  (ref) => UnlockTransitCard(ref.watch(transitCardRepositoryProvider)),
);
final pairPhysicalCardUseCaseProvider = Provider<PairPhysicalCard>(
  (ref) => PairPhysicalCard(ref.watch(transitCardRepositoryProvider)),
);
final loadSubscriptionUseCaseProvider = Provider<LoadSubscription>(
  (ref) => LoadSubscription(ref.watch(transitCardRepositoryProvider)),
);
final executeTurnstilePassUseCaseProvider = Provider<ExecuteTurnstilePass>(
  (ref) => ExecuteTurnstilePass(ref.watch(transitCardRepositoryProvider)),
);
final checkNfcEligibilityUseCaseProvider = Provider<CheckNfcEligibility>(
  (ref) => CheckNfcEligibility(ref.watch(transitCredentialServiceProvider)),
);

final validateTopUpAmountUseCaseProvider = Provider<ValidateTopUpAmount>(
  (ref) => const ValidateTopUpAmount(),
);
final getPaymentMethodsUseCaseProvider = Provider<GetPaymentMethods>(
  (ref) => GetPaymentMethods(ref.watch(balanceRepositoryProvider)),
);
final addPaymentMethodUseCaseProvider = Provider<AddPaymentMethod>(
  (ref) => AddPaymentMethod(ref.watch(balanceRepositoryProvider)),
);
final removePaymentMethodUseCaseProvider = Provider<RemovePaymentMethod>(
  (ref) => RemovePaymentMethod(ref.watch(balanceRepositoryProvider)),
);
final setDefaultPaymentMethodUseCaseProvider =
    Provider<SetDefaultPaymentMethod>(
  (ref) => SetDefaultPaymentMethod(ref.watch(balanceRepositoryProvider)),
);
final confirmTopUpPaymentUseCaseProvider = Provider<ConfirmTopUpPayment>(
  (ref) => ConfirmTopUpPayment(ref.watch(balanceRepositoryProvider)),
);

final getRecentTransactionsUseCaseProvider = Provider<GetRecentTransactions>(
  (ref) => GetRecentTransactions(ref.watch(transactionRepositoryProvider)),
);
final getTransactionHistoryUseCaseProvider = Provider<GetTransactionHistory>(
  (ref) => GetTransactionHistory(ref.watch(transactionRepositoryProvider)),
);
final getTransactionDetailUseCaseProvider = Provider<GetTransactionDetail>(
  (ref) => GetTransactionDetail(ref.watch(transactionRepositoryProvider)),
);
final submitTransactionDisputeUseCaseProvider =
    Provider<SubmitTransactionDispute>(
  (ref) => SubmitTransactionDispute(ref.watch(transactionRepositoryProvider)),
);

final getLastTransactionLocationUseCaseProvider =
    Provider<GetLastTransactionLocation>(
  (ref) => GetLastTransactionLocation(ref.watch(mapRepositoryProvider)),
);
final getNearbyTransitStopsUseCaseProvider = Provider<GetNearbyTransitStops>(
  (ref) => GetNearbyTransitStops(ref.watch(mapRepositoryProvider)),
);
final getDeviceLocationUseCaseProvider = Provider<GetDeviceLocation>(
  (ref) => GetDeviceLocation(ref.watch(deviceLocationServiceProvider)),
);
final reportLocationDiscrepancyUseCaseProvider =
    Provider<ReportLocationDiscrepancy>(
  (ref) => ReportLocationDiscrepancy(ref.watch(mapRepositoryProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfile>(
  (ref) => GetProfile(ref.watch(profileRepositoryProvider)),
);
final updateProfileUseCaseProvider = Provider<UpdateProfile>(
  (ref) => UpdateProfile(ref.watch(profileRepositoryProvider)),
);
final changePasswordUseCaseProvider = Provider<ChangePassword>(
  (ref) => ChangePassword(ref.watch(profileRepositoryProvider)),
);
final getPreferencesUseCaseProvider = Provider<GetPreferences>(
  (ref) => GetPreferences(ref.watch(preferencesRepositoryProvider)),
);
final updateThemeUseCaseProvider = Provider<UpdateTheme>(
  (ref) => UpdateTheme(ref.watch(preferencesRepositoryProvider)),
);
final updateLanguageUseCaseProvider = Provider<UpdateLanguage>(
  (ref) => UpdateLanguage(ref.watch(preferencesRepositoryProvider)),
);
final updateUserPreferencesUseCaseProvider = Provider<UpdateUserPreferences>(
  (ref) => UpdateUserPreferences(ref.watch(preferencesRepositoryProvider)),
);
final clearAppCacheUseCaseProvider = Provider<ClearAppCache>(
  (ref) => ClearAppCache(ref.watch(preferencesRepositoryProvider)),
);

final getFaqsUseCaseProvider = Provider<GetFaqs>(
  (ref) => GetFaqs(ref.watch(supportRepositoryProvider)),
);
final getHelpArticleUseCaseProvider = Provider<GetHelpArticle>(
  (ref) => GetHelpArticle(ref.watch(supportRepositoryProvider)),
);
final toggleArticleBookmarkUseCaseProvider = Provider<ToggleArticleBookmark>(
  (ref) => ToggleArticleBookmark(ref.watch(supportRepositoryProvider)),
);
final submitArticleFeedbackUseCaseProvider = Provider<SubmitArticleFeedback>(
  (ref) => SubmitArticleFeedback(ref.watch(supportRepositoryProvider)),
);
final createSupportTicketUseCaseProvider = Provider<CreateSupportTicket>(
  (ref) => CreateSupportTicket(ref.watch(supportRepositoryProvider)),
);

// ============================================================================
// REACTIVE APPLICATION STATE CONTROLLERS
// ============================================================================

/// Reactive state notifier for the authenticated [AppUser].
class CurrentUserController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    return ref.watch(authRepositoryProvider).getCurrentUserSync();
  }

  void refresh() {
    state = ref.read(authRepositoryProvider).getCurrentUserSync();
  }

  void setUser(AppUser? user) {
    state = user;
  }
}

final currentUserControllerProvider =
    NotifierProvider<CurrentUserController, AppUser?>(
  CurrentUserController.new,
);

/// Reactive state notifier for [UserPreferences] (theme, language, toggles).
class PreferencesController extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    return ref.watch(getPreferencesUseCaseProvider).sync();
  }

  Future<void> setThemeMode(AppThemeModePreference mode) async {
    final res = await ref.read(updateThemeUseCaseProvider)(mode);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }

  Future<void> setLanguage(String localeCode) async {
    final res = await ref.read(updateLanguageUseCaseProvider)(localeCode);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }

  Future<void> updatePreferences(UserPreferences updated) async {
    final res = await ref.read(updateUserPreferencesUseCaseProvider)(updated);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }

  Future<void> clearCache() async {
    final res = await ref.read(clearAppCacheUseCaseProvider)();
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }
}

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, UserPreferences>(
  PreferencesController.new,
);

/// Reactive state notifier for the active [TransitCard] and all user cards.
class TransitCardController extends Notifier<TransitCard> {
  @override
  TransitCard build() {
    return ref.watch(getTransitCardUseCaseProvider).sync();
  }

  List<TransitCard> get allCards => ref.read(getUserCardsUseCaseProvider).sync();

  void refresh() {
    state = ref.read(getTransitCardUseCaseProvider).sync();
  }

  Future<void> selectCard(String cardId) async {
    final res = await ref.read(selectActiveCardUseCaseProvider)(cardId);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
      ref.read(transactionsControllerProvider.notifier).refresh();
    }
  }

  Future<Result<TransitCard>> lockCard({
    bool reportStolenTo153 = false,
    String? reason,
  }) async {
    final res = await ref.read(lockTransitCardUseCaseProvider)(
      cardId: state.id,
      reportStolenTo153: reportStolenTo153,
      reason: reason,
    );
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
    return res;
  }

  Future<Result<TransitCard>> unlockCard(String otpCode) async {
    final res = await ref.read(unlockTransitCardUseCaseProvider)(
      cardId: state.id,
      otpCode: otpCode,
    );
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
    return res;
  }

  Future<Result<TransitCard>> pairPhysicalCard({
    required String serialNumber,
    required String alias,
  }) async {
    final res = await ref.read(pairPhysicalCardUseCaseProvider)(
      serialNumber: serialNumber,
      alias: alias,
    );
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
      ref.read(transactionsControllerProvider.notifier).refresh();
    }
    return res;
  }

  Future<Result<TransitCard>> loadSubscription({
    required int addedPasses,
    required double price,
    required String packageTitle,
    required String paymentMethodLabel,
  }) async {
    final res = await ref.read(loadSubscriptionUseCaseProvider)(
      cardId: state.id,
      addedPasses: addedPasses,
      price: price,
      packageTitle: packageTitle,
      paymentMethodLabel: paymentMethodLabel,
    );
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
      ref.read(transactionsControllerProvider.notifier).refresh();
    }
    return res;
  }

  Future<Result<TransitCard>> executeTurnstilePass({
    String stationName = '',
    String lineDescription = '',
    String category = 'metro',
    required double fareAmount,
    required String methodLabel,
    double latitude = 41.0082,
    double longitude = 28.9784,
    bool useSubscription = false,
  }) async {
    final res = await ref.read(executeTurnstilePassUseCaseProvider)(
      cardId: state.id,
      stationName: stationName,
      lineDescription: lineDescription,
      category: category,
      fareAmount: fareAmount,
      methodLabel: methodLabel,
      latitude: latitude,
      longitude: longitude,
      useSubscription: useSubscription,
    );
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
      ref.read(transactionsControllerProvider.notifier).refresh();
    }
    return res;
  }
}

final transitCardControllerProvider =
    NotifierProvider<TransitCardController, TransitCard>(
  TransitCardController.new,
);

/// Reactive state notifier for saved [PaymentMethod] items.
class PaymentMethodsController extends Notifier<List<PaymentMethod>> {
  @override
  List<PaymentMethod> build() {
    return ref.watch(getPaymentMethodsUseCaseProvider).sync();
  }

  PaymentMethod? get defaultMethod {
    if (state.isEmpty) return null;
    for (final m in state) {
      if (m.isDefault) return m;
    }
    return state.first;
  }

  Future<Result<PaymentMethod>> addCard({
    required String rawCardNumber,
    required String cardholderName,
    required String expiryInput,
    required String cvv,
    bool saveForFuture = true,
  }) async {
    final res = await ref.read(addPaymentMethodUseCaseProvider)(
      rawCardNumber: rawCardNumber,
      cardholderName: cardholderName,
      expiryInput: expiryInput,
      cvv: cvv,
      saveForFuture: saveForFuture,
    );
    state = ref.read(getPaymentMethodsUseCaseProvider).sync();
    return res;
  }

  Future<void> removeCard(String methodId) async {
    final res = await ref.read(removePaymentMethodUseCaseProvider)(methodId);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }

  Future<void> setDefault(String methodId) async {
    final res =
        await ref.read(setDefaultPaymentMethodUseCaseProvider)(methodId);
    if (res.valueOrNull != null) {
      state = res.valueOrNull!;
    }
  }
}

final paymentMethodsControllerProvider =
    NotifierProvider<PaymentMethodsController, List<PaymentMethod>>(
  PaymentMethodsController.new,
);

/// Reactive state notifier for the active card's [TransitTransaction] list.
class TransactionsController extends Notifier<List<TransitTransaction>> {
  @override
  List<TransitTransaction> build() {
    final activeCard = ref.watch(transitCardControllerProvider);
    return ref
        .watch(getTransactionHistoryUseCaseProvider)
        .sync(cardId: activeCard.id);
  }

  void refresh() {
    final activeCard = ref.read(transitCardControllerProvider);
    state = ref
        .read(getTransactionHistoryUseCaseProvider)
        .sync(cardId: activeCard.id);
  }
}

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, List<TransitTransaction>>(
  TransactionsController.new,
);

/// Pending top-up draft state shared between Top-Up (14), Confirm (17),
/// Payment OTP (18), Success (19), and Failure (20) screens.
class TopUpDraftState {
  const TopUpDraftState({
    required this.amount,
    required this.paymentMethodId,
    required this.orderReference,
    this.simulateGatewayFailure = false,
    this.isSubscription = false,
    this.subscriptionPasses = 0,
    this.subscriptionTitle = 'Tam MaviHat Aylık Abonman',
    this.lastResult,
    this.lastErrorMessage,
    this.lastErrorCode = 'ERR-4012',
  });

  final double amount;
  final String paymentMethodId;
  final String orderReference;
  final bool simulateGatewayFailure;
  final bool isSubscription;
  final int subscriptionPasses;
  final String subscriptionTitle;
  final TopUpResult? lastResult;
  final String? lastErrorMessage;
  final String lastErrorCode;

  TopUpDraftState copyWith({
    double? amount,
    String? paymentMethodId,
    String? orderReference,
    bool? simulateGatewayFailure,
    bool? isSubscription,
    int? subscriptionPasses,
    String? subscriptionTitle,
    TopUpResult? lastResult,
    String? lastErrorMessage,
    String? lastErrorCode,
  }) {
    return TopUpDraftState(
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      orderReference: orderReference ?? this.orderReference,
      simulateGatewayFailure:
          simulateGatewayFailure ?? this.simulateGatewayFailure,
      isSubscription: isSubscription ?? this.isSubscription,
      subscriptionPasses: subscriptionPasses ?? this.subscriptionPasses,
      subscriptionTitle: subscriptionTitle ?? this.subscriptionTitle,
      lastResult: lastResult ?? this.lastResult,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }
}

class TopUpDraftController extends Notifier<TopUpDraftState> {
  @override
  TopUpDraftState build() {
    final methods = ref.watch(paymentMethodsControllerProvider);
    final defaultId = methods.isNotEmpty ? methods.first.id : 'pm_troy_4821';
    return TopUpDraftState(
      amount: 150.0,
      paymentMethodId: defaultId,
      orderReference: 'MVH-2026-84920',
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(
      amount: amount,
      isSubscription: false,
      subscriptionPasses: 0,
    );
  }

  void setSubscriptionPackage({
    required double price,
    required int passes,
    required String title,
  }) {
    state = state.copyWith(
      amount: price,
      isSubscription: true,
      subscriptionPasses: passes,
      subscriptionTitle: title,
    );
  }

  void setPaymentMethod(String methodId) {
    state = state.copyWith(paymentMethodId: methodId);
  }

  void setSimulateFailure(bool value) {
    state = state.copyWith(simulateGatewayFailure: value);
  }

  Future<Result<TopUpResult>> executePayment({required String otpCode}) async {
    final activeCard = ref.read(transitCardControllerProvider);
    final req = TopUpRequest(
      cardId: activeCard.id,
      amount: state.amount,
      paymentMethodId: state.paymentMethodId,
      orderReference: state.orderReference,
      simulateGatewayFailure: state.simulateGatewayFailure,
      isSubscription: state.isSubscription,
      subscriptionPasses: state.subscriptionPasses,
      subscriptionTitle: state.subscriptionTitle,
    );
    final result = await ref.read(confirmTopUpPaymentUseCaseProvider)(
      request: req,
      otpCode: otpCode,
    );

    result.fold(
      onFailure: (failure) {
        state = state.copyWith(
          lastErrorMessage: failure.message,
          lastErrorCode: failure.code,
        );
      },
      onSuccess: (topUpResult) {
        state = state.copyWith(lastResult: topUpResult);
        ref.read(transitCardControllerProvider.notifier).refresh();
        ref.read(transactionsControllerProvider.notifier).refresh();
      },
    );

    return result;
  }
}

final topUpDraftControllerProvider =
    NotifierProvider<TopUpDraftController, TopUpDraftState>(
  TopUpDraftController.new,
);
