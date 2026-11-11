import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/user_preferences.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<AppUser>> call() => _repository.getProfile();
  AppUser? sync() => _repository.getProfileSync();
}

class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<AppUser>> call({
    required String displayName,
    required String email,
    required String phoneNumber,
  }) async {
    final cleanName = displayName.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phoneNumber.trim();
    if (cleanName.length < 3) {
      return const Err(
        ValidationFailure(message: 'Ad ve soyad en az 3 karakter olmalıdır.'),
      );
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const Err(
        ValidationFailure(message: 'Lütfen geçerli bir e-posta adresi girin.'),
      );
    }
    if (cleanPhone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen geçerli bir telefon numarası girin.',
        ),
      );
    }
    return _repository.updateProfile(
      displayName: cleanName,
      email: cleanEmail,
      phoneNumber: cleanPhone,
    );
  }
}

class ChangePassword {
  const ChangePassword(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Lütfen mevcut şifrenizi girin.'),
      );
    }
    if (newPassword.length < 8) {
      return const Err(
        ValidationFailure(message: 'Yeni şifreniz en az 8 karakter olmalıdır.'),
      );
    }
    if (newPassword != confirmPassword) {
      return const Err(
        ValidationFailure(message: 'Yeni şifreler birbiriyle eşleşmiyor.'),
      );
    }
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

class GetPreferences {
  const GetPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call() => _repository.getPreferences();
  UserPreferences sync() => _repository.getPreferencesSync();
}

class UpdateTheme {
  const UpdateTheme(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call(AppThemeModePreference mode) {
    final current = _repository.getPreferencesSync();
    return _repository.savePreferences(current.copyWith(themeMode: mode));
  }
}

class UpdateLanguage {
  const UpdateLanguage(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call(String localeCode) {
    final current = _repository.getPreferencesSync();
    return _repository.savePreferences(
      current.copyWith(localeCode: localeCode),
    );
  }
}

class UpdateUserPreferences {
  const UpdateUserPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call(UserPreferences updated) {
    return _repository.savePreferences(updated);
  }
}

class ClearAppCache {
  const ClearAppCache(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call() => _repository.clearAppCache();
}

