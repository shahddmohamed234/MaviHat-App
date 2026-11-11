enum AppThemeModePreference {
  system,
  light,
  dark,
}

/// Domain entity representing user preferences and notification/accessibility
/// settings persisted via Hive CE.
class UserPreferences {
  const UserPreferences({
    required this.themeMode,
    required this.localeCode,
    required this.onboardingCompleted,
    required this.highContrast,
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.transitAlertsEnabled,
    required this.lowBalanceAlertsEnabled,
    required this.promoAlertsEnabled,
    required this.proximityServiceEnabled,
    required this.autoTopUpEnabled,
    required this.autoTopUpThreshold,
    required this.autoTopUpAmount,
    required this.cacheSizeMb,
  });

  final AppThemeModePreference themeMode;
  final String localeCode; // 'tr', 'en', 'ar'
  final bool onboardingCompleted;
  final bool highContrast;
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool transitAlertsEnabled;
  final bool lowBalanceAlertsEnabled;
  final bool promoAlertsEnabled;
  final bool proximityServiceEnabled;
  final bool autoTopUpEnabled;
  final double autoTopUpThreshold;
  final double autoTopUpAmount;
  final double cacheSizeMb;

  UserPreferences copyWith({
    AppThemeModePreference? themeMode,
    String? localeCode,
    bool? onboardingCompleted,
    bool? highContrast,
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? transitAlertsEnabled,
    bool? lowBalanceAlertsEnabled,
    bool? promoAlertsEnabled,
    bool? proximityServiceEnabled,
    bool? autoTopUpEnabled,
    double? autoTopUpThreshold,
    double? autoTopUpAmount,
    double? cacheSizeMb,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      highContrast: highContrast ?? this.highContrast,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      transitAlertsEnabled: transitAlertsEnabled ?? this.transitAlertsEnabled,
      lowBalanceAlertsEnabled:
          lowBalanceAlertsEnabled ?? this.lowBalanceAlertsEnabled,
      promoAlertsEnabled: promoAlertsEnabled ?? this.promoAlertsEnabled,
      proximityServiceEnabled:
          proximityServiceEnabled ?? this.proximityServiceEnabled,
      autoTopUpEnabled: autoTopUpEnabled ?? this.autoTopUpEnabled,
      autoTopUpThreshold: autoTopUpThreshold ?? this.autoTopUpThreshold,
      autoTopUpAmount: autoTopUpAmount ?? this.autoTopUpAmount,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
    );
  }
}

