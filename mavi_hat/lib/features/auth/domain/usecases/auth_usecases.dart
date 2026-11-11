import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';
import '../repositories/phone_otp_service.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String emailOrPhone,
    required String password,
  }) async {
    final trimmedInput = emailOrPhone.trim();
    if (trimmedInput.isEmpty) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen e-posta adresinizi veya telefon numaranızı girin.',
        ),
      );
    }
    if (password.length < 6) {
      return const Err(
        ValidationFailure(
          message: 'Şifreniz en az 6 karakter olmalıdır.',
        ),
      );
    }
    return _repository.signIn(
      emailOrPhone: trimmedInput,
      password: password,
    );
  }
}

class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
    String? phoneNumber,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    if (cleanName.length < 3) {
      return const Err(
        ValidationFailure(message: 'Lütfen adınızı ve soyadınızı tam girin.'),
      );
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const Err(
        ValidationFailure(message: 'Geçerli bir e-posta adresi girin.'),
      );
    }
    if (password.length < 8) {
      return const Err(
        ValidationFailure(message: 'Şifreniz en az 8 karakter olmalıdır.'),
      );
    }
    if (password != confirmPassword) {
      return const Err(
        ValidationFailure(message: 'Girdiğiniz şifreler eşleşmiyor.'),
      );
    }
    if (!acceptedTerms) {
      return const Err(
        ValidationFailure(
          message:
              'Devam etmek için Kullanım Koşulları ve KVKK metnini onaylayın.',
        ),
      );
    }
    return _repository.signUp(
      fullName: cleanName,
      email: cleanEmail,
      password: password,
      phoneNumber: phoneNumber,
    );
  }
}

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}

class ObserveAuthState {
  const ObserveAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.observeAuthState();
  AppUser? currentUserSync() => _repository.getCurrentUserSync();
}

class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) async {
    final clean = email.trim();
    if (!clean.contains('@') || !clean.contains('.')) {
      return const Err(
        ValidationFailure(message: 'Lütfen geçerli bir e-posta adresi girin.'),
      );
    }
    return _repository.resetPassword(email: clean);
  }
}

class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String confirmationText,
    required bool acknowledgedConsequences,
  }) async {
    if (!acknowledgedConsequences) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen kalıcı silme sonuçlarını onaylama kutusunu işaretleyin.',
        ),
      );
    }
    if (confirmationText.trim().toUpperCase() != 'HESABIMI SİL' &&
        confirmationText.trim().toUpperCase() != 'HESABIMI SIL') {
      return const Err(
        ValidationFailure(
          message: 'Onaylamak için kutuya "HESABIMI SİL" yazmalısınız.',
        ),
      );
    }
    return _repository.deleteAccount(confirmationText: confirmationText.trim());
  }
}

class RequestPhoneOtp {
  const RequestPhoneOtp(this._service);

  final PhoneOtpService _service;

  Future<Result<OtpChallenge>> call({
    required String phoneNumber,
    String purpose = 'auth',
  }) {
    return _service.requestOtp(phoneNumber: phoneNumber, purpose: purpose);
  }
}

class VerifyPhoneOtp {
  const VerifyPhoneOtp(this._service);

  final PhoneOtpService _service;

  Future<Result<bool>> call({
    required String challengeId,
    required String code,
  }) async {
    final clean = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 6) {
      return const Err(
        ValidationFailure(message: 'Lütfen 6 haneli doğrulama kodunu tam girin.'),
      );
    }
    return _service.verifyOtp(challengeId: challengeId, code: clean);
  }
}

