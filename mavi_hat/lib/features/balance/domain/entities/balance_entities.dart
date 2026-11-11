/// Tokenized payment method entity.
///
/// Enforces the security rule that raw PAN and CVV are never stored in domain
/// entities, Hive CE, or Firestore—only safe metadata and a sandbox token.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.bankName,
    required this.lastFour,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.isDefault,
    required this.providerTokenReference,
  });

  final String id;
  final String brand;
  final String bankName;
  final String lastFour;
  final int expiryMonth;
  final int expiryYear;
  final String cardholderName;
  final bool isDefault;
  final String providerTokenReference;

  String get formattedExpiry =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().padLeft(2, '0')}';

  String get maskedDisplay => '$brand •••• $lastFour';

  PaymentMethod copyWith({
    String? id,
    String? brand,
    String? bankName,
    String? lastFour,
    int? expiryMonth,
    int? expiryYear,
    String? cardholderName,
    bool? isDefault,
    String? providerTokenReference,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      bankName: bankName ?? this.bankName,
      lastFour: lastFour ?? this.lastFour,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      providerTokenReference:
          providerTokenReference ?? this.providerTokenReference,
    );
  }
}

/// Request object for a balance or monthly subscription top-up operation.
class TopUpRequest {
  const TopUpRequest({
    required this.cardId,
    required this.amount,
    required this.paymentMethodId,
    required this.orderReference,
    this.simulateGatewayFailure = false,
    this.isSubscription = false,
    this.subscriptionPasses = 0,
    this.subscriptionTitle,
  });

  final String cardId;
  final double amount;
  final String paymentMethodId;
  final String orderReference;
  final bool simulateGatewayFailure;
  final bool isSubscription;
  final int subscriptionPasses;
  final String? subscriptionTitle;
}

/// Result returned when a top-up or subscription payment succeeds atomically.
class TopUpResult {
  const TopUpResult({
    required this.transactionId,
    required this.referenceCode,
    required this.cardId,
    required this.maskedCardNumber,
    required this.addedAmount,
    required this.previousBalance,
    required this.updatedBalance,
    required this.paymentMethodSummary,
    required this.timestamp,
    this.isSubscription = false,
    this.addedSubscriptionPasses = 0,
    this.updatedSubscriptionRemaining = 0,
  });

  final String transactionId;
  final String referenceCode;
  final String cardId;
  final String maskedCardNumber;
  final double addedAmount;
  final double previousBalance;
  final double updatedBalance;
  final String paymentMethodSummary;
  final DateTime timestamp;
  final bool isSubscription;
  final int addedSubscriptionPasses;
  final int updatedSubscriptionRemaining;
}
