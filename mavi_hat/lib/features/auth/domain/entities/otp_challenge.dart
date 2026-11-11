/// Represents an active SMS OTP challenge in development/sandbox or production.
class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.maskedPhoneNumber,
    required this.expiresInSeconds,
    required this.isDevelopmentMode,
    this.devTestCodeHint = '123456',
  });

  final String challengeId;
  final String maskedPhoneNumber;
  final int expiresInSeconds;
  final bool isDevelopmentMode;
  final String devTestCodeHint;
}

