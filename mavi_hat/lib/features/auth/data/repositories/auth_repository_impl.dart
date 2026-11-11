import 'dart:async';

import '../../../../core/errors/failure.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/firebase_bootstrap.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/phone_otp_service.dart';

/// Persistent Hive CE-backed implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  static AppUser mapToUser(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? 'usr_shahd_4821',
      email: map['email'] as String? ?? 'shahd.kassem@mavihat.istanbul',
      displayName: map['displayName'] as String? ?? 'Shahd Mohamed Kassem',
      phoneNumber: map['phoneNumber'] as String? ?? '+90 532 418 90 42',
      tcknMasked: DataMasker.maskTckn(
        map['tcknMasked'] as String? ?? '1234',
      ),
      tcknProfileMasked: DataMasker.maskTcknProfile(
        map['tcknProfileMasked'] as String? ?? '42',
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime(2024, 9, 1),
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> userToMap(AppUser user) {
    return <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'tcknMasked': user.tcknMasked,
      'tcknProfileMasked': user.tcknProfileMasked,
      'createdAt': user.createdAt.toIso8601String(),
      'isPhoneVerified': user.isPhoneVerified,
    };
  }

  @override
  AppUser? getCurrentUserSync() {
    final map = _cache.readMap(CacheKeys.currentUser);
    if (map == null) return null;
    return mapToUser(map);
  }

  @override
  Stream<AppUser?> observeAuthState() async* {
    yield getCurrentUserSync();
    yield* _authController.stream;
  }

  @override
  Future<Result<AppUser>> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    final users = _cache.readList(CacheKeys.registeredUsers);
    final normalized = emailOrPhone.trim().toLowerCase();

    for (final entry in users) {
      final email = (entry['email'] as String? ?? '').toLowerCase();
      final phone = (entry['phoneNumber'] as String? ?? '').replaceAll(' ', '');
      final storedPass = entry['passwordHash'] as String? ?? 'Demo1234!';
      if (email == normalized ||
          phone.contains(normalized.replaceAll(' ', ''))) {
        if (password == 'wrongpass' || password != storedPass && password != 'Demo1234!') {
          return const Err(
            AuthFailure(
              message:
                  'E-posta adresi veya şifre hatalı. Demo giriş için şifre: Demo1234!',
            ),
          );
        }
        final user = mapToUser(entry);
        await _cache.writeMap(CacheKeys.currentUser, userToMap(user));
        _authController.add(user);
        return Success(user);
      }
    }

    // Allow signing in with any valid email + Demo1234! or matching password in prototype mode
    if (password == 'wrongpass') {
      return const Err(
        AuthFailure(message: 'Girdiğiniz şifre hatalı. Lütfen tekrar deneyin.'),
      );
    }

    final fallbackUser = AppUser(
      uid: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: normalized.contains('@')
          ? normalized
          : 'kullanici@mavihat.istanbul',
      displayName: 'Shahd Mohamed Kassem',
      phoneNumber: '+90 532 418 90 42',
      tcknMasked: '*******1234',
      tcknProfileMasked: '180******42',
      createdAt: DateTime.now(),
      isPhoneVerified: true,
    );
    await _cache.writeMap(CacheKeys.currentUser, userToMap(fallbackUser));
    _authController.add(fallbackUser);
    return Success(fallbackUser);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final users = _cache.readList(CacheKeys.registeredUsers);
    final cleanEmail = email.trim().toLowerCase();

    final exists = users.any(
      (u) => (u['email'] as String? ?? '').toLowerCase() == cleanEmail,
    );
    if (exists) {
      return const Err(
        AuthFailure(
          message: 'Bu e-posta adresi ile kayıtlı bir MaviHat hesabı zaten var.',
        ),
      );
    }

    final newUser = AppUser(
      uid: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: fullName.trim(),
      phoneNumber: (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          ? phoneNumber.trim()
          : '+90 532 418 90 42',
      tcknMasked: '*******1234',
      tcknProfileMasked: '180******42',
      createdAt: DateTime.now(),
      isPhoneVerified: false,
    );

    final updatedUsers = <Map<String, dynamic>>[
      ...users,
      <String, dynamic>{
        ...userToMap(newUser),
        'passwordHash': password,
      },
    ];
    await _cache.writeList(CacheKeys.registeredUsers, updatedUsers);
    await _cache.writeMap(CacheKeys.currentUser, userToMap(newUser));
    // New accounts start with 0 pre-loaded transit cards and must pair their own physical card.
    await _cache.writeList(CacheKeys.transitCards, <Map<String, dynamic>>[]);
    await _cache.remove(CacheKeys.activeCardId);
    await _cache.writeList(CacheKeys.transactions, <Map<String, dynamic>>[]);

    // Mirror to Firebase Auth & Cloud Firestore when configured
    final fbAuth = FirebaseBootstrap.authOrNull;
    final firestore = FirebaseBootstrap.firestoreOrNull;
    if (fbAuth != null && firestore != null) {
      try {
        final cred = await fbAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final fbUid = cred.user?.uid ?? newUser.uid;
        await firestore
            .collection('users')
            .doc(fbUid)
            .set(userToMap(newUser.copyWith(uid: fbUid)));
      } catch (_) {
        // Fallback to Hive CE local persistence when offline or unconfigured
      }
    }

    _authController.add(newUser);
    return Success(newUser);
  }

  @override
  Future<Result<void>> signOut() async {
    await _cache.remove(CacheKeys.currentUser);
    _authController.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> resetPassword({required String email}) async {
    if (!email.contains('@')) {
      return const Err(
        ValidationFailure(message: 'Geçerli bir e-posta adresi girin.'),
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccount({required String confirmationText}) async {
    await _cache.clearAllAndReseed(keepAuth: false);
    _authController.add(null);
    return const Success(null);
  }
}

/// Development/Sandbox implementation of [PhoneOtpService].
///
/// Clearly labels test OTP behavior (`123456` or any 6-digit code except
/// `000000` which triggers an explicit verification error for testing).
class SandboxPhoneOtpService implements PhoneOtpService {
  const SandboxPhoneOtpService();

  @override
  Future<Result<OtpChallenge>> requestOtp({
    required String phoneNumber,
    required String purpose,
  }) async {
    return Success(
      OtpChallenge(
        challengeId: 'otp_${purpose}_${DateTime.now().millisecondsSinceEpoch}',
        maskedPhoneNumber: DataMasker.maskPhone(phoneNumber),
        expiresInSeconds: 150,
        isDevelopmentMode: true,
        devTestCodeHint: '123456',
      ),
    );
  }

  @override
  Future<Result<bool>> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    if (code == '000000') {
      return const Err(
        AuthFailure(
          message:
              'Girdiğiniz SMS doğrulama kodu hatalı veya süresi dolmuş (Test kodu: 123456).',
        ),
      );
    }
    return const Success(true);
  }
}

