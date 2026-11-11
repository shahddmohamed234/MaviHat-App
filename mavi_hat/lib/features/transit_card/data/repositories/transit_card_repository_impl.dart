import '../../../../core/errors/failure.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/data_masker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/transit_card.dart';
import '../../domain/repositories/transit_card_repository.dart';

/// Persistent Hive CE-backed implementation of [TransitCardRepository].
class TransitCardRepositoryImpl implements TransitCardRepository {
  TransitCardRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  static const List<String> _turkishMonths = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String formatSubscriptionRenewalDate(DateTime date) {
    final monthName = _turkishMonths[(date.month - 1).clamp(0, 11)];
    return '${date.day} $monthName ${date.year}';
  }

  static TransitCard mapToCard(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'active';
    return TransitCard(
      id: map['id'] as String? ?? 'card_mavihat_4821',
      alias: map['alias'] as String? ?? 'İstanbul Şehir Kartı',
      cardTypeLabel: map['cardTypeLabel'] as String? ?? 'KİŞİSEL TAM KART',
      maskedNumber: DataMasker.maskCardNumber(
        map['lastFour'] as String? ?? '4821',
      ),
      fullMaskedSerial: DataMasker.maskCardNumber(
        map['lastFour'] as String? ?? '4821',
        includePrefix: true,
      ),
      lastFour: map['lastFour'] as String? ?? '4821',
      holderName: map['holderName'] as String? ?? 'SHAHD MOHAMED KASSEM',
      maskedTckn: DataMasker.maskTckn(
        map['maskedTckn'] as String? ?? '1234',
      ),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      status: statusStr == 'locked' ? CardStatus.locked : CardStatus.active,
      subscriptionUsed: (map['subscriptionUsed'] as num?)?.toInt() ?? 0,
      subscriptionTotal: (map['subscriptionTotal'] as num?)?.toInt() ?? 200,
      subscriptionRenewsAt:
          map['subscriptionRenewsAt'] as String? ?? '15 Kasım 2026',
      lastSyncedAt: DateTime.tryParse(map['lastSyncedAt'] as String? ?? '') ??
          DateTime(2026, 10, 24, 18, 42),
      lastStationName: map['lastStationName'] as String? ?? 'Kadıköy İskelesi',
      subscriptionExpiresAt: DateTime.tryParse(
        map['subscriptionExpiresAtIso'] as String? ?? '',
      ),
    );
  }

  static Map<String, dynamic> cardToMap(TransitCard card) {
    return <String, dynamic>{
      'id': card.id,
      'alias': card.alias,
      'cardTypeLabel': card.cardTypeLabel,
      'maskedNumber': card.maskedNumber,
      'fullMaskedSerial': card.fullMaskedSerial,
      'lastFour': card.lastFour,
      'holderName': card.holderName,
      'maskedTckn': card.maskedTckn,
      'balance': card.balance,
      'status': card.status == CardStatus.locked ? 'locked' : 'active',
      'subscriptionUsed': card.subscriptionUsed,
      'subscriptionTotal': card.subscriptionTotal,
      'subscriptionRenewsAt': card.subscriptionRenewsAt,
      'lastSyncedAt': card.lastSyncedAt.toIso8601String(),
      'lastStationName': card.lastStationName,
      if (card.subscriptionExpiresAt != null)
        'subscriptionExpiresAtIso':
            card.subscriptionExpiresAt!.toIso8601String(),
    };
  }

  @override
  List<TransitCard> getUserCardsSync() {
    final raw = _cache.readList(CacheKeys.transitCards);
    if (raw.isEmpty) {
      return const <TransitCard>[];
    }
    return raw.map(mapToCard).toList();
  }

  @override
  TransitCard getActiveCardSync() {
    final cards = getUserCardsSync();
    if (cards.isEmpty) {
      final userMap = _cache.readMap(CacheKeys.currentUser);
      final holder =
          (userMap?['displayName'] as String? ?? 'MAVİHAT KULLANICISI')
              .toUpperCase();
      final tckn = DataMasker.maskTckn(
        userMap?['tcknMasked'] as String? ?? '1234',
      );
      return TransitCard.unpaired(holderName: holder, maskedTckn: tckn);
    }
    final activeId = _cache.readString(CacheKeys.activeCardId);
    if (activeId != null) {
      for (final card in cards) {
        if (card.id == activeId) return card;
      }
    }
    return cards.first;
  }

  @override
  Future<Result<TransitCard>> getActiveCard() async {
    return Success(getActiveCardSync());
  }

  @override
  Future<Result<List<TransitCard>>> getUserCards() async {
    return Success(getUserCardsSync());
  }

  @override
  Future<Result<TransitCard>> selectActiveCard(String cardId) async {
    final cards = getUserCardsSync();
    TransitCard? selected;
    for (final c in cards) {
      if (c.id == cardId) {
        selected = c;
        break;
      }
    }
    if (selected == null) {
      return const Err(
        ValidationFailure(message: 'Seçilen kart bulunamadı.'),
      );
    }
    await _cache.writeString(CacheKeys.activeCardId, selected.id);
    return Success(selected);
  }

  @override
  Future<Result<TransitCard>> lockCard({
    required String cardId,
    required bool reportStolenTo153,
    String? reason,
  }) async {
    final cards = getUserCardsSync();
    TransitCard? updated;
    final newList = <Map<String, dynamic>>[];

    for (final card in cards) {
      if (card.id == cardId) {
        updated = card.copyWith(
          status: CardStatus.locked,
          lastSyncedAt: DateTime.now(),
        );
        newList.add(cardToMap(updated));
      } else {
        newList.add(cardToMap(card));
      }
    }

    if (updated == null) {
      return const Err(
        ValidationFailure(message: 'Kilitlenecek kart bulunamadı.'),
      );
    }

    await _cache.writeList(CacheKeys.transitCards, newList);
    return Success(updated);
  }

  @override
  Future<Result<TransitCard>> unlockCard({
    required String cardId,
    required String otpCode,
  }) async {
    if (otpCode == '000000') {
      return const Err(
        AuthFailure(
          message: 'Girilen SMS doğrulama kodu geçersiz. Lütfen tekrar deneyin.',
          code: 'ERR-UNLOCK-OTP',
        ),
      );
    }

    final cards = getUserCardsSync();
    TransitCard? updated;
    final newList = <Map<String, dynamic>>[];

    for (final card in cards) {
      if (card.id == cardId) {
        updated = card.copyWith(
          status: CardStatus.active,
          lastSyncedAt: DateTime.now(),
        );
        newList.add(cardToMap(updated));
      } else {
        newList.add(cardToMap(card));
      }
    }

    if (updated == null) {
      return const Err(
        ValidationFailure(message: 'Kilidi açılacak kart bulunamadı.'),
      );
    }

    await _cache.writeList(CacheKeys.transitCards, newList);
    return Success(updated);
  }

  @override
  Future<Result<TransitCard>> pairPhysicalCard({
    required String serialLastFour,
    required String alias,
  }) async {
    final cards = getUserCardsSync();
    final userMap = _cache.readMap(CacheKeys.currentUser);
    final holderName =
        (userMap?['displayName'] as String? ?? 'MAVİHAT KULLANICISI')
            .toUpperCase();
    final maskedTckn = DataMasker.maskTckn(
      userMap?['tcknMasked'] as String? ?? '1234',
    );

    if (cards.isEmpty) {
      final newCardId = 'card_mavihat_$serialLastFour';
      final newCard = TransitCard(
        id: newCardId,
        alias: alias,
        cardTypeLabel: 'KİŞİSEL TAM KART',
        maskedNumber: DataMasker.maskCardNumber(serialLastFour),
        fullMaskedSerial: DataMasker.maskCardNumber(
          serialLastFour,
          includePrefix: true,
        ),
        lastFour: serialLastFour,
        holderName: holderName,
        maskedTckn: maskedTckn,
        balance: 0.0,
        status: CardStatus.active,
        subscriptionUsed: 0,
        subscriptionTotal: 0,
        subscriptionRenewsAt: 'Abonman Yok',
        lastSyncedAt: DateTime.now(),
        lastStationName: 'Henüz turnike geçişi yapılmadı',
      );
      await _cache.writeList(
        CacheKeys.transitCards,
        <Map<String, dynamic>>[cardToMap(newCard)],
      );
      await _cache.writeString(CacheKeys.activeCardId, newCardId);
      return Success(newCard);
    }

    final active = getActiveCardSync();
    final updatedActive = active.copyWith(
      alias: alias,
      lastFour: serialLastFour,
      maskedNumber: DataMasker.maskCardNumber(serialLastFour),
      fullMaskedSerial:
          DataMasker.maskCardNumber(serialLastFour, includePrefix: true),
      lastSyncedAt: DateTime.now(),
    );

    final updatedList = cards
        .map((c) => c.id == active.id ? updatedActive : c)
        .toList();
    await _cache.writeList(
      CacheKeys.transitCards,
      updatedList.map(cardToMap).toList(),
    );
    return Success(updatedActive);
  }

  @override
  Future<Result<TransitCard>> loadSubscription({
    required String cardId,
    required int addedPasses,
    required double price,
    required String packageTitle,
    required String paymentMethodLabel,
  }) async {
    final active = getActiveCardSync();
    if (active.isUnpaired) {
      return const Err(
        ValidationFailure(
          message:
              'Abonman yükleyebilmek için önce fiziksel ulaşım kartınızı eşleştirmelisiniz.',
        ),
      );
    }
    if (active.isLocked) {
      return const Err(
        CardLockedFailure(
          message:
              'Kartınız güvenlik kilidi altında olduğu için abonman yüklenemez.',
        ),
      );
    }

    if (active.hasActiveSubscription) {
      return Err(
        ValidationFailure(
          message:
              'Bu ay için aktif abonmanınız devam ediyor (${active.subscriptionRemaining} geçiş hakkı kaldı • Bitiş: ${active.subscriptionRenewsAt}). Ayda yalnızca 1 kez abonman yüklenebilir; mevcut haklarınız bittiğinde veya bir sonraki ay tekrar yükleyebilirsiniz.',
        ),
      );
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));
    final updatedCard = active.copyWith(
      subscriptionUsed: 0,
      subscriptionTotal: addedPasses,
      subscriptionRenewsAt: formatSubscriptionRenewalDate(expiresAt),
      subscriptionExpiresAt: expiresAt,
      lastSyncedAt: now,
    );

    final cards = getUserCardsSync();
    final updatedCards = cards
        .map((c) => c.id == active.id ? updatedCard : c)
        .toList();
    await _cache.writeList(
      CacheKeys.transitCards,
      updatedCards.map(cardToMap).toList(),
    );

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final refSuffix = (now.millisecondsSinceEpoch % 90000 + 10000).toString();
    final subTxnMap = <String, dynamic>{
      'id': 'txn_sub_$refSuffix',
      'referenceCode': 'TXN-SUB-$refSuffix',
      'cardId': active.id,
      'maskedCardNumber': active.maskedNumber,
      'title': 'Aylık Abonman Yükleme (+$addedPasses Geçiş)',
      'subtitle': '$paymentMethodLabel • $packageTitle',
      'lineCode': '$packageTitle (+$addedPasses Geçiş Hakkı)',
      'validatorCode': 'MVH-SUB-01 (Dijital Abonman)',
      'tariffType': packageTitle,
      'category': 'topUp',
      'type': 'topUp',
      'amount': price,
      'balanceAfter': active.balance,
      'timestampIso': now.toIso8601String(),
      'displayDateGroup': 'BUGÜN, 24 EKİM',
      'displayTime': '$hh:$mm',
      'latitude': 41.0082,
      'longitude': 28.9784,
      'status': 'completed',
    };

    final existingTxns = _cache.readList(CacheKeys.transactions);
    await _cache.writeList(
      CacheKeys.transactions,
      <Map<String, dynamic>>[subTxnMap, ...existingTxns],
    );

    return Success(updatedCard);
  }

  @override
  Future<Result<TransitCard>> executeTurnstilePass({
    required String cardId,
    String stationName = '',
    String lineDescription = '',
    String category = 'metro',
    required double fareAmount,
    required String methodLabel,
    double latitude = 41.0082,
    double longitude = 28.9784,
    bool useSubscription = false,
  }) async {
    final active = getActiveCardSync();
    if (active.isUnpaired) {
      return const Err(
        ValidationFailure(
          message:
              'Turnike geçişi için önce fiziksel ulaşım kartınızı eşleştirmelisiniz.',
        ),
      );
    }
    if (active.isLocked) {
      return const Err(
        CardLockedFailure(
          message:
              'Kartınız güvenlik kilidi altında olduğu için turnike geçişi yapılamaz.',
        ),
      );
    }

    final now = DateTime.now();
    final existingTxns = _cache.readList(CacheKeys.transactions);

    // Automatic validator machine detection when stationName is not explicitly passed
    String resolvedStation = stationName;
    String resolvedLine = lineDescription;
    String resolvedCategory = category;
    double resolvedLat = latitude;
    double resolvedLng = longitude;

    if (resolvedStation.isEmpty) {
      // Check if there was a recent fare tap within the last 15 minutes
      Map<String, dynamic>? latestRecentFare;
      for (final t in existingTxns) {
        if (t['cardId'] == active.id && t['type'] == 'fare') {
          final lastTime = DateTime.tryParse(t['timestampIso'] as String? ?? '');
          if (lastTime != null && now.difference(lastTime).abs().inMinutes < 15) {
            latestRecentFare = t;
          }
          break;
        }
      }
      if (latestRecentFare != null) {
        resolvedStation =
            latestRecentFare['title'] as String? ?? 'Kadıköy İskelesi';
        resolvedLine = latestRecentFare['lineCode'] as String? ??
            'Şehir Hatları • Kadıköy - Eminönü Vapur Hattı';
        resolvedCategory =
            latestRecentFare['category'] as String? ?? 'ferry';
        resolvedLat =
            (latestRecentFare['latitude'] as num?)?.toDouble() ?? 40.9912;
        resolvedLng =
            (latestRecentFare['longitude'] as num?)?.toDouble() ?? 29.0228;
      } else {
        final nextTerminal =
            AutoValidatorTerminal.nextTerminalAfter(active.lastStationName);
        resolvedStation = nextTerminal.stationName;
        resolvedLine = nextTerminal.lineDescription;
        resolvedCategory = nextTerminal.category;
        resolvedLat = nextTerminal.lat;
        resolvedLng = nextTerminal.lng;
      }
    }

    // Count consecutive fare taps at this exact station within the last 15 minutes:
    // 0 previous taps at this station -> 1. Basım (Abonman)
    // 1 previous tap  at this station -> 2. Basım (TL)
    // 2 previous taps at this station -> 3. Basım (TL)
    // 3 previous taps at this station -> 4. Basım (TL)
    // 4 previous taps at this station -> 5. Basım (TL) ...
    int tapCountAtStation = 0;
    for (final t in existingTxns) {
      if (t['cardId'] == active.id && t['type'] == 'fare') {
        final lastTime = DateTime.tryParse(t['timestampIso'] as String? ?? '');
        if (lastTime != null &&
            now.difference(lastTime).abs().inMinutes < 15 &&
            t['title'] == resolvedStation) {
          tapCountAtStation++;
        } else {
          break;
        }
      }
    }

    final int currentTapNumber = tapCountAtStation + 1;

    // Rule: 1. Basım uses Monthly Subscription (if remaining > 0);
    //       2., 3., 4., 5.+ Basım at the turnstile automatically deducts TL balance!
    final bool shouldUseSubscription =
        currentTapNumber == 1 && active.subscriptionRemaining > 0;

    double newBalance = active.balance;
    int newSubUsed = active.subscriptionUsed;

    if (shouldUseSubscription) {
      newSubUsed += 1;
    } else {
      if (active.balance < fareAmount) {
        return Err(
          ValidationFailure(
            message: currentTapNumber >= 2
                ? 'Aynı turnikede $currentTapNumber. basım TL bakiyeden çekilir (${fareAmount.toStringAsFixed(2)} TL). Bakiyeniz yetersiz.'
                : 'Kart bakiyeniz bu geçiş için yetersiz. Lütfen bakiye yükleyin.',
          ),
        );
      }
      newBalance = double.parse(
        (active.balance - fareAmount).toStringAsFixed(2),
      );
    }

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final refSuffix = (now.millisecondsSinceEpoch % 90000 + 10000).toString();
    final txnId = 'txn_pass_$refSuffix';
    final refCode = 'TXN-20261024-$refSuffix';
    final isQr = methodLabel.toUpperCase().contains('QR');

    final newTxnMap = <String, dynamic>{
      'id': txnId,
      'referenceCode': refCode,
      'cardId': active.id,
      'maskedCardNumber': active.maskedNumber,
      'title': resolvedStation,
      'subtitle': shouldUseSubscription
          ? '$resolvedLine • 1. Basım (Abonman)'
          : '$resolvedLine • $currentTapNumber. Basım (TL Bakiye)',
      'lineCode': resolvedLine,
      'validatorCode': isQr
          ? 'VLD-QR-02 (Otomatik Validatör • $currentTapNumber. Basım)'
          : 'VLD-NFC-01 (Otomatik Validatör • $currentTapNumber. Basım)',
      'tariffType': shouldUseSubscription
          ? 'Aylık Abonman Geçişi - 1. Basım ($methodLabel)'
          : 'Tam Biniş Sabit Tarifesi - $currentTapNumber. Basım ($methodLabel)',
      'category': resolvedCategory,
      'type': 'fare',
      'amount': shouldUseSubscription ? 0.0 : -fareAmount,
      'balanceAfter': newBalance,
      'timestampIso': now.toIso8601String(),
      'displayDateGroup': 'BUGÜN, 24 EKİM',
      'displayTime': '$hh:$mm',
      'latitude': resolvedLat,
      'longitude': resolvedLng,
      'status': 'completed',
    };

    final updatedTxns = <Map<String, dynamic>>[newTxnMap, ...existingTxns];

    // Check Automatic Balance Top-Up (Otomatik Bakiye Yükleme Talimatı)
    final prefsMap = _cache.readMap(CacheKeys.userPreferences);
    final autoEnabled = prefsMap?['autoTopUpEnabled'] as bool? ?? false;
    final autoThreshold =
        (prefsMap?['autoTopUpThreshold'] as num?)?.toDouble() ?? 50.0;
    final autoAmount =
        (prefsMap?['autoTopUpAmount'] as num?)?.toDouble() ?? 150.0;
    final savedMethods = _cache.readList(CacheKeys.paymentMethods);

    if (autoEnabled && newBalance < autoThreshold && savedMethods.isNotEmpty) {
      final defaultMethod = savedMethods.firstWhere(
        (m) => m['isDefault'] == true,
        orElse: () => savedMethods.first,
      );
      newBalance = double.parse((newBalance + autoAmount).toStringAsFixed(2));
      final autoRef =
          ((now.millisecondsSinceEpoch + 7) % 90000 + 10000).toString();
      final autoTxnMap = <String, dynamic>{
        'id': 'txn_autotopup_$autoRef',
        'referenceCode': 'TXN-AUTO-$autoRef',
        'cardId': active.id,
        'maskedCardNumber': active.maskedNumber,
        'title': 'Otomatik Bakiye Dolumu',
        'subtitle':
            '${defaultMethod['brand']} •••• ${defaultMethod['lastFour']} • Alt Limit (₺${autoThreshold.toInt()}) Tetiklendi',
        'lineCode': 'Otomatik Talimat • Anında Dolum',
        'validatorCode': 'MVH-AUTO-01 (Otomatik Talimat)',
        'tariffType': 'Otomatik Bakiye Yükleme Talimatı',
        'category': 'topUp',
        'type': 'topUp',
        'amount': autoAmount,
        'balanceAfter': newBalance,
        'timestampIso': now.add(const Duration(seconds: 1)).toIso8601String(),
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '$hh:$mm',
        'latitude': resolvedLat,
        'longitude': resolvedLng,
        'status': 'completed',
      };
      updatedTxns.insert(0, autoTxnMap);
    }

    final updatedCard = active.copyWith(
      balance: newBalance,
      subscriptionUsed: newSubUsed,
      lastSyncedAt: now,
      lastStationName: resolvedStation,
    );

    final cards = getUserCardsSync();
    final updatedCards = cards
        .map((c) => c.id == active.id ? updatedCard : c)
        .toList();
    await _cache.writeList(
      CacheKeys.transitCards,
      updatedCards.map(cardToMap).toList(),
    );

    await _cache.writeList(CacheKeys.transactions, updatedTxns);

    return Success(updatedCard);
  }
}

/// Active NFC & Contactless Turnstile Credential Service.
class PrototypeTransitCredentialService implements TransitCredentialService {
  const PrototypeTransitCredentialService();

  @override
  NfcEligibilityStatus checkEligibility(TransitCard card) {
    if (card.isUnpaired) {
      return const NfcEligibilityStatus(
        isProductionAvailable: false,
        isCardActive: false,
        statusTitle: 'Eşleştirilmiş Ulaşım Kartı Yok',
        explanation:
            'NFC temassız geçiş ve QR kod ile ödeme yapabilmek için önce fiziksel MaviHat ulaşım kartınızı hesabınıza eşleştirin.',
        requirements: <String>[
          'Kartım veya Ana Sayfa ekranından fiziksel kart seri numaranızı girerek eşleştirme yapın.',
        ],
      );
    }

    if (card.isLocked) {
      return const NfcEligibilityStatus(
        isProductionAvailable: false,
        isCardActive: false,
        statusTitle: 'Kartınız Kilitli Durumda',
        explanation:
            'Güvenlik kilidi aktif olduğu için bu kart ile NFC turnike geçişi ve QR ödeme yapılamaz.',
        requirements: <String>[
          'Önce Kartım ekranından SMS doğrulaması ile kart kilidini kaldırın.',
        ],
      );
    }

    return const NfcEligibilityStatus(
      isProductionAvailable: true,
      isCardActive: true,
      statusTitle: 'NFC Temassız Geçiş Aktif ve Hazır',
      explanation:
          'Cihazınızı turnike okuyucusuna yaklaştırarak NFC ile anında geçiş yapabilir veya 2 dakikalık dinamik QR kod oluşturarak turnikeden geçebilirsiniz.',
      requirements: <String>[
        'NFC HCE Temassız Ulaşım Kimliği: Aktif',
        'Dinamik Turnike QR Ödeme Modülü: Aktif (30 sn döngülü)',
        'Otomatik Validatör İstasyon Algılama: Aktif',
      ],
    );
  }
}
