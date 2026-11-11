import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

/// Abstract repository for authentication and account lifecycle operations.
abstract interface class AuthRepository {
  AppUser? getCurrentUserSync();

  Stream<AppUser?> observeAuthState();

  Future<Result<AppUser>> signIn({
    required String emailOrPhone,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> resetPassword({
    required String email,
  });

  Future<Result<void>> deleteAccount({
    required String confirmationText,
  });
}

