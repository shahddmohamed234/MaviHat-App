import '../../../../core/utils/result.dart';
import '../entities/balance_entities.dart';

/// Abstract payment gateway contract for tokenizing cards and processing
/// sandbox 3D Secure payments.
abstract interface class PaymentGateway {
  Future<Result<PaymentMethod>> tokenizeCard({
    required String rawCardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  });

  Future<Result<String>> authorize3DSecure({
    required TopUpRequest request,
    required String otpCode,
  });
}

/// Abstract repository for balance top-ups and saved payment methods.
abstract interface class BalanceRepository {
  List<PaymentMethod> getPaymentMethodsSync();

  Future<Result<List<PaymentMethod>>> getPaymentMethods();

  Future<Result<PaymentMethod>> addPaymentMethod({
    required String rawCardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required bool saveForFuture,
  });

  Future<Result<List<PaymentMethod>>> removePaymentMethod(String methodId);

  Future<Result<List<PaymentMethod>>> setDefaultPaymentMethod(String methodId);

  /// Atomically updates card balance and appends a `topUp` transaction record
  /// ONLY after [PaymentGateway.authorize3DSecure] succeeds.
  Future<Result<TopUpResult>> confirmTopUpPayment({
    required TopUpRequest request,
    required String otpCode,
  });
}

