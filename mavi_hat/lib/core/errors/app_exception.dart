/// Application-level exceptions thrown inside the Data layer.
///
/// Data repositories catch [AppException] instances and convert them into
/// domain-safe [Failure] objects before returning to Use Cases.
class AppException implements Exception {
  const AppException({
    required this.message,
    this.code = 'ERR-GENERIC',
  });

  final String message;
  final String code;

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code = 'ERR-AUTH',
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'ERR-CACHE',
  });
}

class PaymentException extends AppException {
  const PaymentException({
    required super.message,
    super.code = 'ERR-4012',
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'ERR-VALIDATION',
  });
}

