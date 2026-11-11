enum TransactionFilter {
  all,
  metro,
  bus,
  ferry,
  topUp,
}

enum TransactionType {
  fare,
  topUp,
  subscription,
  refund,
}

/// Domain entity representing a transit card fare or balance top-up record.
class TransitTransaction {
  const TransitTransaction({
    required this.id,
    required this.referenceCode,
    required this.cardId,
    required this.maskedCardNumber,
    required this.title,
    required this.subtitle,
    required this.lineCode,
    required this.validatorCode,
    required this.tariffType,
    required this.category,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    required this.displayDateGroup,
    required this.displayTime,
    required this.latitude,
    required this.longitude,
    this.status = 'completed',
  });

  final String id;
  final String referenceCode;
  final String cardId;
  final String maskedCardNumber;
  final String title;
  final String subtitle;
  final String lineCode;
  final String validatorCode;
  final String tariffType;
  final String category; // 'metro', 'bus', 'ferry', 'topUp'
  final TransactionType type;
  final double amount;
  final double balanceAfter;
  final DateTime timestamp;
  final String displayDateGroup;
  final String displayTime;
  final double latitude;
  final double longitude;
  final String status;

  bool get isCredit => amount > 0;
}

/// Dispute/issue report submitted for a specific transaction (`13._i_lem_detay`).
class TransactionDispute {
  const TransactionDispute({
    required this.id,
    required this.transactionId,
    required this.referenceCode,
    required this.reason,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String transactionId;
  final String referenceCode;
  final String reason;
  final String description;
  final DateTime createdAt;
}

