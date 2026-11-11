import '../../../../core/utils/result.dart';
import '../entities/otp_challenge.dart';

/// Abstract service for requesting and verifying 6-digit SMS OTP codes.
///
/// Clearly separates development/test OTP verification from production SMS
/// gateways.
abstract interface class PhoneOtpService {
  Future<Result<OtpChallenge>> requestOtp({
    required String phoneNumber,
    required String purpose,
  });

  Future<Result<bool>> verifyOtp({
    required String challengeId,
    required String code,
  });
}

