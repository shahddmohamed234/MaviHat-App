/// Route path constants for all 31 Stitch MaviHat screens.
abstract final class RouteNames {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String authOtp = '/auth-otp';

  // Bottom Navigation Shell Tabs
  static const String home = '/home';
  static const String myCard = '/my-card';
  static const String topUp = '/top-up';
  static const String map = '/map';
  static const String profile = '/profile';

  // Transit Card & NFC & Lock Flows
  static const String nfcContactlessInfo = '/my-card/nfc-info';
  static const String lockCardConfirm = '/my-card/lock-confirm';
  static const String cardLockedState = '/my-card/locked';

  // Transactions Flows
  static const String transactionHistory = '/transactions';
  static const String transactionDetail = '/transactions/detail';

  // Balance & Payment Flows
  static const String paymentMethods = '/top-up/payment-methods';
  static const String addPaymentCard = '/top-up/add-card';
  static const String confirmTopUp = '/top-up/confirm';
  static const String paymentOtp = '/top-up/payment-otp';
  static const String topUpSuccess = '/top-up/success';
  static const String topUpFailure = '/top-up/failure';

  // Profile, Settings, Support & Account Lifecycle Flows
  static const String personalInfoSecurity = '/profile/personal-info';
  static const String settingsPreferences = '/profile/settings';
  static const String helpAndFaq = '/profile/help';
  static const String helpArticleDetail = '/profile/help/article';
  static const String logoutConfirm = '/profile/logout-confirm';
  static const String deleteAccountConfirm = '/profile/delete-account';
  static const String offlineStatus = '/offline';
}

