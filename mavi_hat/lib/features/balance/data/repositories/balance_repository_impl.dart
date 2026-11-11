import '../../../../core/errors/failure.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/utils/result.dart';
import '../../../transit_card/data/repositories/transit_card_repository_impl.dart';
import '../../../transit_card/domain/entities/transit_card.dart';
import '../../domain/entities/balance_entities.dart';
import '../../domain/repositories/balance_repository.dart';

/// Sandbox implementation of [PaymentGateway].
///
/// Never stores or logs raw PAN or CVV; returns a tokenized [PaymentMethod]
/// and simulates 3D Secure authorization.
class SandboxPaymentGateway implements PaymentGateway {
  const SandboxPaymentGateway();

  @override
  Future<Result<PaymentMethod>> tokenizeCard({
    required String rawCardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    final digits = rawCardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final lastFour = DataMasker.extractLastFour(digits);

    final String brand;
    final String bankName;
    if (digits.startsWith('9792')) {
      brand = 'TROY';
      bankName = 'Ziraat Bankası Banka Kartı';
    } else if (digits.startsWith('5')) {
      brand = 'Mastercard';
      bankName = 'İş Bankası Maximum Kredi Kartı';
    } else if (digits.startsWith('4')) {
      brand = 'Visa';
      bankName = 'Garanti BBVA Bonus Kart';
    } else {
      brand = 'TROY';
      bankName = 'VakıfBank Worldcard';
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    return Success(
      PaymentMethod(
        id: 'pm_${brand.toLowerCase()}_${lastFour}_$stamp',
        brand: brand,
        bankName: bankName,
        lastFour: lastFour,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardholderName: cardholderName.toUpperCase(),
        isDefault: false,
        providerTokenReference: 'tok_sandbox_${brand.toLowerCase()}_$lastFour',
      ),
    );
  }

  @override
  Future<Result<String>> authorize3DSecure({
    required TopUpRequest request,
    required String otpCode,
  }) async {
    if (request.simulateGatewayFailure || otpCode == '000000') {
      return const Err(
        PaymentFailure(
          message:
              'Bankanız 3D Secure doğrulamasını onaylamadı veya provizyon zaman aşımına uğradı. Kartınızdan hiçbir tutar çekilmedi.',
          code: 'ERR-4012',
        ),
      );
    }
    return Success('AUTH-3DS-${DateTime.now().millisecondsSinceEpoch}');
  }
}

/// Persistent Hive CE-backed implementation of [BalanceRepository].
class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl({
    required this.cache,
    required this.paymentGateway,
  });

  final LocalCacheDataSource cache;
  final PaymentGateway paymentGateway;

  static PaymentMethod mapToMethod(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String? ?? 'pm_troy_4821',
      brand: map['brand'] as String? ?? 'TROY',
      bankName: map['bankName'] as String? ?? 'Ziraat Bankası Banka Kartı',
      lastFour: DataMasker.extractLastFour(
        map['lastFour'] as String? ?? '4821',
      ),
      expiryMonth: (map['expiryMonth'] as num?)?.toInt() ?? 8,
      expiryYear: (map['expiryYear'] as num?)?.toInt() ?? 28,
      cardholderName:
          map['cardholderName'] as String? ?? 'SHAHD MOHAMED KASSEM',
      isDefault: map['isDefault'] as bool? ?? false,
      providerTokenReference:
          map['providerTokenReference'] as String? ?? 'tok_sandbox_4821',
    );
  }

  static Map<String, dynamic> methodToMap(PaymentMethod method) {
    // Strictly stores only tokenized/safe metadata; NEVER raw PAN or CVV.
    return <String, dynamic>{
      'id': method.id,
      'brand': method.brand,
      'bankName': method.bankName,
      'lastFour': method.lastFour,
      'expiryMonth': method.expiryMonth,
      'expiryYear': method.expiryYear,
      'cardholderName': method.cardholderName,
      'isDefault': method.isDefault,
      'providerTokenReference': method.providerTokenReference,
    };
  }

  @override
  List<PaymentMethod> getPaymentMethodsSync() {
    final raw = cache.readList(CacheKeys.paymentMethods);
    return raw.map(mapToMethod).toList();
  }

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods() async {
    return Success(getPaymentMethodsSync());
  }

  @override
  Future<Result<PaymentMethod>> addPaymentMethod({
    required String rawCardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required bool saveForFuture,
  }) async {
    final tokenResult = await paymentGateway.tokenizeCard(
      rawCardNumber: rawCardNumber,
      cardholderName: cardholderName,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: cvv,
    );

    if (tokenResult is Err<PaymentMethod>) {
      return tokenResult;
    }

    final tokenized = (tokenResult as Success<PaymentMethod>).value;
    if (!saveForFuture) {
      return Success(tokenized);
    }

    final existing = getPaymentMethodsSync();
    final shouldBeDefault = existing.isEmpty;
    final savedMethod = tokenized.copyWith(isDefault: shouldBeDefault);
    final updated = <PaymentMethod>[...existing, savedMethod];

    await cache.writeList(
      CacheKeys.paymentMethods,
      updated.map(methodToMap).toList(),
    );
    return Success(savedMethod);
  }

  @override
  Future<Result<List<PaymentMethod>>> removePaymentMethod(
    String methodId,
  ) async {
    final existing = getPaymentMethodsSync();
    final remaining = existing.where((m) => m.id != methodId).toList();
    if (remaining.isNotEmpty && !remaining.any((m) => m.isDefault)) {
      remaining[0] = remaining[0].copyWith(isDefault: true);
    }
    await cache.writeList(
      CacheKeys.paymentMethods,
      remaining.map(methodToMap).toList(),
    );
    return Success(remaining);
  }

  @override
  Future<Result<List<PaymentMethod>>> setDefaultPaymentMethod(
    String methodId,
  ) async {
    final existing = getPaymentMethodsSync();
    final updated = existing
        .map((m) => m.copyWith(isDefault: m.id == methodId))
        .toList();
    await cache.writeList(
      CacheKeys.paymentMethods,
      updated.map(methodToMap).toList(),
    );
    return Success(updated);
  }

  @override
  Future<Result<TopUpResult>> confirmTopUpPayment({
    required TopUpRequest request,
    required String otpCode,
  }) async {
    // 1. Verify target card exists and is not locked
    final rawCards = cache.readList(CacheKeys.transitCards);
    final cards = rawCards.map(TransitCardRepositoryImpl.mapToCard).toList();
    final targetIndex = cards.indexWhere((c) => c.id == request.cardId);
    if (targetIndex < 0) {
      return const Err(
        NotFoundFailure(message: 'Bakiye yüklenecek ulaşım kartı bulunamadı.'),
      );
    }
    final targetCard = cards[targetIndex];
    if (targetCard.status == CardStatus.locked) {
      return const Err(
        CardLockedFailure(
          message:
              'Kilitli karta bakiye yüklenemez. Lütfen önce kart kilidini kaldırın.',
        ),
      );
    }
    if (request.isSubscription && targetCard.hasActiveSubscription) {
      return Err(
        ValidationFailure(
          message:
              'Bu ay için aktif abonmanınız devam ediyor (${targetCard.subscriptionRemaining} geçiş hakkı kaldı • Bitiş: ${targetCard.subscriptionRenewsAt}). Ayda yalnızca 1 kez abonman yüklenebilir; mevcut haklarınız bittiğinde veya bir sonraki ay tekrar yükleyebilirsiniz.',
        ),
      );
    }

    // 2. Authorize payment via sandbox PaymentGateway
    final authResult = await paymentGateway.authorize3DSecure(
      request: request,
      otpCode: otpCode,
    );
    if (authResult is Err<String>) {
      // Do NOT modify balance or create transaction on payment failure!
      return Err(authResult.failure);
    }

    // 3. Payment succeeded: atomically update card balance OR subscription and prepend transaction
    final previousBalance = targetCard.balance;
    final updatedBalance = request.isSubscription
        ? previousBalance
        : double.parse((previousBalance + request.amount).toStringAsFixed(2));
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));

    final methods = getPaymentMethodsSync();
    final usedMethod = methods
        .where((m) => m.id == request.paymentMethodId)
        .firstOrNull;
    final methodSummary = usedMethod != null
        ? '${usedMethod.brand} •••• ${usedMethod.lastFour}'
        : 'TROY •••• 4821';

    final updatedCard = targetCard.copyWith(
      balance: updatedBalance,
      subscriptionUsed: request.isSubscription ? 0 : targetCard.subscriptionUsed,
      subscriptionTotal: request.isSubscription
          ? request.subscriptionPasses
          : targetCard.subscriptionTotal,
      subscriptionRenewsAt: request.isSubscription
          ? TransitCardRepositoryImpl.formatSubscriptionRenewalDate(expiresAt)
          : targetCard.subscriptionRenewsAt,
      subscriptionExpiresAt: request.isSubscription
          ? expiresAt
          : targetCard.subscriptionExpiresAt,
      lastSyncedAt: now,
    );
    cards[targetIndex] = updatedCard;

    await cache.writeList(
      CacheKeys.transitCards,
      cards.map(TransitCardRepositoryImpl.cardToMap).toList(),
    );

    final suffix = (now.millisecondsSinceEpoch % 90000 + 10000).toString();
    final referenceCode = 'TXN-20261024-$suffix';
    final txnId = 'txn_topup_${now.millisecondsSinceEpoch}';
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    final pkgTitle = request.subscriptionTitle ?? 'Tam MaviHat Aylık Abonman';
    final newTxnMap = <String, dynamic>{
      'id': txnId,
      'referenceCode': referenceCode,
      'cardId': updatedCard.id,
      'maskedCardNumber': updatedCard.maskedNumber,
      'title': request.isSubscription
          ? 'Aylık Abonman Yükleme (+${request.subscriptionPasses} Geçiş)'
          : 'Bakiye Yükleme',
      'subtitle': request.isSubscription
          ? '$methodSummary • $pkgTitle'
          : '$methodSummary • Mobil Uygulama',
      'lineCode': request.isSubscription
          ? '$pkgTitle (+${request.subscriptionPasses} Geçiş Hakkı)'
          : 'Mobil Dolum • Anında Bakiye',
      'validatorCode': request.isSubscription
          ? 'MVH-SUB-01 (Dijital Abonman)'
          : 'MVH-ONL-01 (Sanal POS)',
      'tariffType': request.isSubscription
          ? pkgTitle
          : 'Dijital Bakiye Dolumu',
      'category': 'topUp',
      'type': 'topUp',
      'amount': request.amount,
      'balanceAfter': updatedBalance,
      'timestampIso': now.toIso8601String(),
      'displayDateGroup': 'BUGÜN, 24 EKİM',
      'displayTime': '$hh:$mm',
      'latitude': 41.0082,
      'longitude': 28.9784,
      'status': 'completed',
    };

    final existingTxns = cache.readList(CacheKeys.transactions);
    await cache.writeList(
      CacheKeys.transactions,
      <Map<String, dynamic>>[newTxnMap, ...existingTxns],
    );

    return Success(
      TopUpResult(
        transactionId: txnId,
        referenceCode: referenceCode,
        cardId: updatedCard.id,
        maskedCardNumber: updatedCard.maskedNumber,
        addedAmount: request.amount,
        previousBalance: previousBalance,
        updatedBalance: updatedBalance,
        paymentMethodSummary: methodSummary,
        timestamp: now,
        isSubscription: request.isSubscription,
        addedSubscriptionPasses: request.subscriptionPasses,
        updatedSubscriptionRemaining: updatedCard.subscriptionRemaining,
      ),
    );
  }
}
