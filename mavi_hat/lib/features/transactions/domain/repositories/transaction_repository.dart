import '../../../../core/utils/result.dart';
import '../entities/transit_transaction.dart';

/// Abstract repository for querying transit transactions and submitting
/// transaction disputes.
abstract interface class TransactionRepository {
  List<TransitTransaction> getTransactionsSync({
    String? cardId,
    TransactionFilter filter = TransactionFilter.all,
  });

  Future<Result<List<TransitTransaction>>> getRecentTransactions({
    required String cardId,
    int limit = 4,
  });

  Future<Result<List<TransitTransaction>>> getTransactionHistory({
    required String cardId,
    TransactionFilter filter = TransactionFilter.all,
    int limit = 20,
  });

  Future<Result<TransitTransaction>> getTransactionDetail(String transactionId);

  Future<Result<TransactionDispute>> submitDispute({
    required String transactionId,
    required String reason,
    required String description,
  });
}

