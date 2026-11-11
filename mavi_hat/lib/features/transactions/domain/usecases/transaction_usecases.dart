import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/transit_transaction.dart';
import '../repositories/transaction_repository.dart';

class GetRecentTransactions {
  const GetRecentTransactions(this._repository);

  final TransactionRepository _repository;

  Future<Result<List<TransitTransaction>>> call({
    required String cardId,
    int limit = 4,
  }) =>
      _repository.getRecentTransactions(cardId: cardId, limit: limit);

  List<TransitTransaction> sync({required String cardId, int limit = 4}) {
    final all = _repository.getTransactionsSync(cardId: cardId);
    return all.take(limit).toList();
  }
}

class GetTransactionHistory {
  const GetTransactionHistory(this._repository);

  final TransactionRepository _repository;

  Future<Result<List<TransitTransaction>>> call({
    required String cardId,
    TransactionFilter filter = TransactionFilter.all,
    int limit = 20,
  }) =>
      _repository.getTransactionHistory(
        cardId: cardId,
        filter: filter,
        limit: limit,
      );

  List<TransitTransaction> sync({
    required String cardId,
    TransactionFilter filter = TransactionFilter.all,
  }) =>
      _repository.getTransactionsSync(cardId: cardId, filter: filter);
}

class GetTransactionDetail {
  const GetTransactionDetail(this._repository);

  final TransactionRepository _repository;

  Future<Result<TransitTransaction>> call(String transactionId) =>
      _repository.getTransactionDetail(transactionId);
}

class SubmitTransactionDispute {
  const SubmitTransactionDispute(this._repository);

  final TransactionRepository _repository;

  Future<Result<TransactionDispute>> call({
    required String transactionId,
    required String reason,
    required String description,
  }) async {
    if (reason.trim().isEmpty) {
      return const Err(
        ValidationFailure(message: 'Lütfen bir sorun nedeni seçin.'),
      );
    }
    if (description.trim().length < 5) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen sorunu en az 5 karakter ile kısaca açıklayın.',
        ),
      );
    }
    return _repository.submitDispute(
      transactionId: transactionId,
      reason: reason.trim(),
      description: description.trim(),
    );
  }
}

