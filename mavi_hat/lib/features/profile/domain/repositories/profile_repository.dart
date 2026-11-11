import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/user_preferences.dart';

/// Abstract repository for updating user profile data and security credentials.
abstract interface class ProfileRepository {
  AppUser? getProfileSync();

  Future<Result<AppUser>> getProfile();

  Future<Result<AppUser>> updateProfile({
    required String displayName,
    required String email,
    required String phoneNumber,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Abstract repository for persisting user preferences, theme, and language.
abstract interface class PreferencesRepository {
  UserPreferences getPreferencesSync();

  Future<Result<UserPreferences>> getPreferences();

  Future<Result<UserPreferences>> savePreferences(UserPreferences preferences);

  Future<Result<UserPreferences>> clearAppCache();
}

