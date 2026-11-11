/// Domain-safe failure hierarchy returned inside [Result] objects.
///
/// The Domain and Presentation layers depend only on [Failure] and never
/// on concrete data-source exceptions.
sealed class Failure {
  const Failure({
    required this.message,
    this.code = 'ERR-0000',
  });

  final String message;
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}

final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'ERR-AUTH',
  });
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'ERR-VAL',
  });
}

final class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    super.code = 'ERR-4012',
  });
}

final class CardLockedFailure extends Failure {
  const CardLockedFailure({
    required super.message,
    super.code = 'ERR-CARD-LOCKED',
  });
}

final class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'ERR-CACHE',
  });
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code = 'ERR-NETWORK',
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code = 'ERR-404',
  });
}

