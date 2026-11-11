import '../../../../core/errors/failure.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/profile_repository.dart';

/// Persistent Hive CE-backed implementation of [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  @override
  AppUser? getProfileSync() {
    final map = _cache.readMap(CacheKeys.currentUser);
    if (map == null) return null;
    return AuthRepositoryImpl.mapToUser(map);
  }

  @override
  Future<Result<AppUser>> getProfile() async {
    final user = getProfileSync();
    if (user == null) {
      return const Err(
        AuthFailure(message: 'Aktif kullanıcı oturumu bulunamadı.'),
      );
    }
    return Success(user);
  }

  @override
  Future<Result<AppUser>> updateProfile({
    required String displayName,
    required String email,
    required String phoneNumber,
  }) async {
    final current = getProfileSync();
    if (current == null) {
      return const Err(
        AuthFailure(message: 'Profil güncellemek için giriş yapmalısınız.'),
      );
    }
    final updated = current.copyWith(
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
    );
    await _cache.writeMap(
      CacheKeys.currentUser,
      AuthRepositoryImpl.userToMap(updated),
    );

    // Also update holder name on user's transit cards
    final rawCards = _cache.readList(CacheKeys.transitCards);
    if (rawCards.isNotEmpty) {
      final updatedCards = rawCards
          .map(
            (c) => <String, dynamic>{
              ...c,
              'holderName': displayName.toUpperCase(),
            },
          )
          .toList();
      await _cache.writeList(CacheKeys.transitCards, updatedCards);
    }

    return Success(updated);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword == 'wrongpass') {
      return const Err(
        AuthFailure(message: 'Mevcut şifrenizi hatalı girdiniz.'),
      );
    }
    final users = _cache.readList(CacheKeys.registeredUsers);
    final current = getProfileSync();
    if (current != null && users.isNotEmpty) {
      final updatedUsers = users.map((u) {
        if (u['uid'] == current.uid || u['email'] == current.email) {
          return <String, dynamic>{
            ...u,
            'passwordHash': newPassword,
          };
        }
        return u;
      }).toList();
      await _cache.writeList(CacheKeys.registeredUsers, updatedUsers);
    }
    return const Success(null);
  }
}

/// Persistent Hive CE-backed implementation of [PreferencesRepository].
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  static UserPreferences mapToPrefs(Map<String, dynamic>? map) {
    if (map == null) {
      return const UserPreferences(
        themeMode: AppThemeModePreference.light,
        localeCode: 'tr',
        onboardingCompleted: true,
        highContrast: false,
        biometricEnabled: true,
        twoFactorEnabled: true,
        transitAlertsEnabled: true,
        lowBalanceAlertsEnabled: true,
        promoAlertsEnabled: false,
        proximityServiceEnabled: true,
        autoTopUpEnabled: false,
        autoTopUpThreshold: 50.0,
        autoTopUpAmount: 150.0,
        cacheSizeMb: 14.2,
      );
    }
    final modeStr = map['themeMode'] as String? ?? 'light';
    final themeMode = switch (modeStr) {
      'dark' => AppThemeModePreference.dark,
      'system' => AppThemeModePreference.system,
      _ => AppThemeModePreference.light,
    };

    return UserPreferences(
      themeMode: themeMode,
      localeCode: map['localeCode'] as String? ?? 'tr',
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? true,
      highContrast: map['highContrast'] as bool? ?? false,
      biometricEnabled: map['biometricEnabled'] as bool? ?? true,
      twoFactorEnabled: map['twoFactorEnabled'] as bool? ?? true,
      transitAlertsEnabled: map['transitAlertsEnabled'] as bool? ?? true,
      lowBalanceAlertsEnabled: map['lowBalanceAlertsEnabled'] as bool? ?? true,
      promoAlertsEnabled: map['promoAlertsEnabled'] as bool? ?? false,
      proximityServiceEnabled: map['proximityServiceEnabled'] as bool? ?? true,
      autoTopUpEnabled: map['autoTopUpEnabled'] as bool? ?? false,
      autoTopUpThreshold:
          (map['autoTopUpThreshold'] as num?)?.toDouble() ?? 50.0,
      autoTopUpAmount: (map['autoTopUpAmount'] as num?)?.toDouble() ?? 150.0,
      cacheSizeMb: (map['cacheSizeMb'] as num?)?.toDouble() ?? 14.2,
    );
  }

  static Map<String, dynamic> prefsToMap(UserPreferences prefs) {
    final modeStr = switch (prefs.themeMode) {
      AppThemeModePreference.dark => 'dark',
      AppThemeModePreference.system => 'system',
      AppThemeModePreference.light => 'light',
    };
    return <String, dynamic>{
      'themeMode': modeStr,
      'localeCode': prefs.localeCode,
      'onboardingCompleted': prefs.onboardingCompleted,
      'highContrast': prefs.highContrast,
      'biometricEnabled': prefs.biometricEnabled,
      'twoFactorEnabled': prefs.twoFactorEnabled,
      'transitAlertsEnabled': prefs.transitAlertsEnabled,
      'lowBalanceAlertsEnabled': prefs.lowBalanceAlertsEnabled,
      'promoAlertsEnabled': prefs.promoAlertsEnabled,
      'proximityServiceEnabled': prefs.proximityServiceEnabled,
      'autoTopUpEnabled': prefs.autoTopUpEnabled,
      'autoTopUpThreshold': prefs.autoTopUpThreshold,
      'autoTopUpAmount': prefs.autoTopUpAmount,
      'cacheSizeMb': prefs.cacheSizeMb,
    };
  }

  @override
  UserPreferences getPreferencesSync() {
    final map = _cache.readMap(CacheKeys.userPreferences);
    return mapToPrefs(map);
  }

  @override
  Future<Result<UserPreferences>> getPreferences() async {
    return Success(getPreferencesSync());
  }

  @override
  Future<Result<UserPreferences>> savePreferences(
    UserPreferences preferences,
  ) async {
    await _cache.writeMap(
      CacheKeys.userPreferences,
      prefsToMap(preferences),
    );
    return Success(preferences);
  }

  @override
  Future<Result<UserPreferences>> clearAppCache() async {
    final current = getPreferencesSync();
    final updated = current.copyWith(cacheSizeMb: 0.0);
    await savePreferences(updated);
    return Success(updated);
  }
}

