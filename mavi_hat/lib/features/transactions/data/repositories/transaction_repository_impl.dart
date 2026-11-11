import '../../../../core/errors/failure.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/transit_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Persistent Hive CE-backed implementation of [TransactionRepository].
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  static TransitTransaction mapToTransaction(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'fare';
    final type = switch (typeStr) {
      'topUp' => TransactionType.topUp,
      'subscription' => TransactionType.subscription,
      'refund' => TransactionType.refund,
      _ => TransactionType.fare,
    };

    return TransitTransaction(
      id: map['id'] as String? ?? 'txn_kadikoy_94820',
      referenceCode: map['referenceCode'] as String? ?? 'TXN-20261024-94820',
      cardId: map['cardId'] as String? ?? 'card_mavihat_4821',
      maskedCardNumber: map['maskedCardNumber'] as String? ?? '•••• 4821',
      title: map['title'] as String? ?? 'Kadıköy İskelesi',
      subtitle: map['subtitle'] as String? ?? 'Şehir Hatları Vapur Hattı',
      lineCode: map['lineCode'] as String? ?? 'Şehir Hatları • Kadıköy',
      validatorCode: map['validatorCode'] as String? ?? 'VLD-KDK-04',
      tariffType: map['tariffType'] as String? ?? 'Tam Biniş Tarifesi',
      category: map['category'] as String? ?? 'ferry',
      type: type,
      amount: (map['amount'] as num?)?.toDouble() ?? -27.50,
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 245.50,
      timestamp: DateTime.tryParse(map['timestampIso'] as String? ?? '') ??
          DateTime(2026, 10, 24, 18, 42),
      displayDateGroup: map['displayDateGroup'] as String? ?? 'BUGÜN, 24 EKİM',
      displayTime: map['displayTime'] as String? ?? '18:42',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 40.9912,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 29.0228,
      status: map['status'] as String? ?? 'completed',
    );
  }

  @override
  List<TransitTransaction> getTransactionsSync({
    String? cardId,
    TransactionFilter filter = TransactionFilter.all,
  }) {
    final raw = _cache.readList(CacheKeys.transactions);
    var list = raw.map(mapToTransaction).toList();

    if (cardId != null && cardId.isNotEmpty) {
      list = list.where((t) => t.cardId == cardId).toList();
    }

    list = switch (filter) {
      TransactionFilter.all => list,
      TransactionFilter.metro =>
        list.where((t) => t.category == 'metro').toList(),
      TransactionFilter.bus => list.where((t) => t.category == 'bus').toList(),
      TransactionFilter.ferry =>
        list.where((t) => t.category == 'ferry').toList(),
      TransactionFilter.topUp =>
        list.where((t) => t.category == 'topUp').toList(),
    };

    return list;
  }

  @override
  Future<Result<List<TransitTransaction>>> getRecentTransactions({
    required String cardId,
    int limit = 4,
  }) async {
    final all = getTransactionsSync(cardId: cardId);
    return Success(all.take(limit).toList());
  }

  @override
  Future<Result<List<TransitTransaction>>> getTransactionHistory({
    required String cardId,
    TransactionFilter filter = TransactionFilter.all,
    int limit = 20,
  }) async {
    final filtered = getTransactionsSync(cardId: cardId, filter: filter);
    return Success(filtered.take(limit).toList());
  }

  @override
  Future<Result<TransitTransaction>> getTransactionDetail(
    String transactionId,
  ) async {
    final all = getTransactionsSync();
    for (final txn in all) {
      if (txn.id == transactionId || txn.referenceCode == transactionId) {
        return Success(txn);
      }
    }
    if (all.isNotEmpty) {
      return Success(all.first);
    }
    return const Err(
      NotFoundFailure(message: 'İstenen işlem detayı bulunamadı.'),
    );
  }

  @override
  Future<Result<TransactionDispute>> submitDispute({
    required String transactionId,
    required String reason,
    required String description,
  }) async {
    final detailResult = await getTransactionDetail(transactionId);
    final refCode = detailResult.valueOrNull?.referenceCode ?? 'TXN-20261024';
    final now = DateTime.now();
    final dispute = TransactionDispute(
      id: 'dsp_${now.millisecondsSinceEpoch}',
      transactionId: transactionId,
      referenceCode: refCode,
      reason: reason,
      description: description,
      createdAt: now,
    );

    final existing = _cache.readList(CacheKeys.transactionDisputes);
    await _cache.writeList(
      CacheKeys.transactionDisputes,
      <Map<String, dynamic>>[
        ...existing,
        <String, dynamic>{
          'id': dispute.id,
          'transactionId': dispute.transactionId,
          'referenceCode': dispute.referenceCode,
          'reason': dispute.reason,
          'description': dispute.description,
          'createdAt': dispute.createdAt.toIso8601String(),
        },
      ],
    );
    return Success(dispute);
  }
}

