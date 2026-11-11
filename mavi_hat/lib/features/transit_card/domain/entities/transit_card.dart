/// Operational status of a MaviHat transit card.
enum CardStatus {
  active,
  locked,
}

/// Automatically detected turnstile / validator hardware terminal in Istanbul.
class AutoValidatorTerminal {
  const AutoValidatorTerminal({
    required this.stationName,
    required this.lineDescription,
    required this.category,
    required this.validatorCode,
    required this.lat,
    required this.lng,
  });

  final String stationName;
  final String lineDescription;
  final String category;
  final String validatorCode;
  final double lat;
  final double lng;

  static const List<AutoValidatorTerminal> istanbulNetwork =
      <AutoValidatorTerminal>[
    AutoValidatorTerminal(
      stationName: 'Kadıköy İskelesi',
      lineDescription: 'Şehir Hatları • Kadıköy - Eminönü Vapur Hattı',
      category: 'ferry',
      validatorCode: 'VLD-KDK-04 (Turnike #4)',
      lat: 40.9912,
      lng: 29.0228,
    ),
    AutoValidatorTerminal(
      stationName: 'Eminönü T1 Tramvay Durağı',
      lineDescription: 'T1 Kabataş - Bağcılar Tramvay Hattı',
      category: 'tram',
      validatorCode: 'VLD-EMN-02 (Turnike #2)',
      lat: 41.0165,
      lng: 28.9735,
    ),
    AutoValidatorTerminal(
      stationName: 'Karaköy F2 Tünel İstasyonu',
      lineDescription: 'F2 Karaköy - Beyoğlu Tarihi Tünel',
      category: 'tram',
      validatorCode: 'VLD-KRK-01 (Turnike #1)',
      lat: 41.0229,
      lng: 28.9746,
    ),
    AutoValidatorTerminal(
      stationName: 'Taksim M2 Metro İstasyonu',
      lineDescription: 'M2 Yenikapı - Hacıosman Metro Hattı',
      category: 'metro',
      validatorCode: 'VLD-TKS-03 (Turnike #3)',
      lat: 41.0369,
      lng: 28.9850,
    ),
    AutoValidatorTerminal(
      stationName: 'Levent M2/M6 Metro İstasyonu',
      lineDescription: 'M2 Yenikapı - Hacıosman Metro Hattı',
      category: 'metro',
      validatorCode: 'VLD-LVN-05 (Turnike #5)',
      lat: 41.0781,
      lng: 29.0138,
    ),
    AutoValidatorTerminal(
      stationName: 'Beşiktaş İETT Peronları',
      lineDescription: 'İETT • 30D Ortaköy - Kabataş Otobüs Hattı',
      category: 'bus',
      validatorCode: 'VLD-BUS-30D (Araç Validatörü)',
      lat: 41.0422,
      lng: 29.0067,
    ),
    AutoValidatorTerminal(
      stationName: 'Üsküdar M5 Metro İstasyonu',
      lineDescription: 'M5 Üsküdar - Çekmeköy Metro Hattı',
      category: 'metro',
      validatorCode: 'VLD-USK-01 (Turnike #1)',
      lat: 41.0256,
      lng: 29.0151,
    ),
    AutoValidatorTerminal(
      stationName: 'Söğütlüçeşme Metrobüs İstasyonu',
      lineDescription: '34AS Avcılar - Söğütlüçeşme Metrobüs',
      category: 'bus',
      validatorCode: 'VLD-MTB-08 (Turnike #8)',
      lat: 40.9905,
      lng: 29.0378,
    ),
    AutoValidatorTerminal(
      stationName: 'Yenikapı Marmaray İstasyonu',
      lineDescription: 'Marmaray • Halkalı - Gebze Banliyö Hattı',
      category: 'metro',
      validatorCode: 'VLD-MRM-06 (Turnike #6)',
      lat: 41.0054,
      lng: 28.9519,
    ),
    AutoValidatorTerminal(
      stationName: 'Bostancı Deniz Otobüsü İskelesi',
      lineDescription: 'Şehir Hatları • Bostancı - Adalar Vapur Hattı',
      category: 'ferry',
      validatorCode: 'VLD-BST-02 (Turnike #2)',
      lat: 40.9522,
      lng: 29.0942,
    ),
  ];

  /// Returns the next validator terminal in the Istanbul network after
  /// [currentStationName] so each new boarding session automatically detects a
  /// different station along the route.
  static AutoValidatorTerminal nextTerminalAfter(String currentStationName) {
    final idx = istanbulNetwork.indexWhere(
      (t) => t.stationName == currentStationName,
    );
    if (idx < 0) {
      return istanbulNetwork[0];
    }
    return istanbulNetwork[(idx + 1) % istanbulNetwork.length];
  }
}

/// Eligibility status for NFC / Contactless turnstile passage (`TransitCredentialService`).
class NfcEligibilityStatus {
  const NfcEligibilityStatus({
    required this.isProductionAvailable,
    required this.isCardActive,
    required this.statusTitle,
    required this.explanation,
    required this.requirements,
  });

  final bool isProductionAvailable;
  final bool isCardActive;
  final String statusTitle;
  final String explanation;
  final List<String> requirements;
}

/// Domain entity representing a physical MaviHat transit card.
///
/// Full TCKN and full serial numbers are never stored on [TransitCard].
class TransitCard {
  const TransitCard({
    required this.id,
    required this.alias,
    required this.cardTypeLabel,
    required this.maskedNumber,
    required this.fullMaskedSerial,
    required this.lastFour,
    required this.holderName,
    required this.maskedTckn,
    required this.balance,
    required this.status,
    required this.subscriptionUsed,
    required this.subscriptionTotal,
    required this.subscriptionRenewsAt,
    required this.lastSyncedAt,
    required this.lastStationName,
    this.subscriptionExpiresAt,
  });

  /// Official monthly subscription tariff (`₺260,00` for `200` passes).
  static const double monthlySubscriptionPrice = 260.0;
  static const int monthlySubscriptionPasses = 200;

  /// Placeholder state when a newly registered user has not paired a physical
  /// transit card yet.
  factory TransitCard.unpaired({
    String holderName = 'MAVİHAT KULLANICISI',
    String maskedTckn = '*******1234',
  }) {
    return TransitCard(
      id: 'unpaired_card',
      alias: 'Eşleştirilmiş Kart Yok',
      cardTypeLabel: 'FİZİKSEL KART EŞLEŞTİRİN',
      maskedNumber: '•••• ----',
      fullMaskedSerial: 'MH-••••-----',
      lastFour: '----',
      holderName: holderName.toUpperCase(),
      maskedTckn: maskedTckn,
      balance: 0.0,
      status: CardStatus.active,
      subscriptionUsed: 0,
      subscriptionTotal: 0,
      subscriptionRenewsAt: '-',
      lastSyncedAt: DateTime(2026, 10, 24),
      lastStationName: 'Henüz kart eşleştirilmedi',
    );
  }

  final String id;
  final String alias;
  final String cardTypeLabel;
  final String maskedNumber;
  final String fullMaskedSerial;
  final String lastFour;
  final String holderName;
  final String maskedTckn;
  final double balance;
  final CardStatus status;
  final int subscriptionUsed;
  final int subscriptionTotal;
  final String subscriptionRenewsAt;
  final DateTime lastSyncedAt;
  final String lastStationName;
  final DateTime? subscriptionExpiresAt;

  bool get isUnpaired => id == 'unpaired_card';
  bool get isLocked => status == CardStatus.locked;
  bool get isActive => status == CardStatus.active && !isUnpaired;

  /// True when the 30-day monthly subscription validity period has passed.
  bool get isSubscriptionExpired =>
      subscriptionExpiresAt != null &&
      DateTime.now().isAfter(subscriptionExpiresAt!);

  int get subscriptionRemaining => isSubscriptionExpired
      ? 0
      : (subscriptionTotal - subscriptionUsed).clamp(0, subscriptionTotal);

  double get subscriptionProgress =>
      subscriptionTotal > 0 ? subscriptionUsed / subscriptionTotal : 0.0;

  /// True when the card currently has an active monthly subscription with
  /// remaining passes in the current 30-day cycle.
  bool get hasActiveSubscription =>
      !isUnpaired && subscriptionRemaining > 0 && !isSubscriptionExpired;

  /// Monthly subscription (`₺260,00`) can only be loaded once per month, OR
  /// reloaded when all passes are used up (`subscriptionRemaining == 0`) or
  /// the 30-day cycle expires (`isSubscriptionExpired`).
  bool get canLoadSubscription =>
      !isUnpaired && !isLocked && !hasActiveSubscription;

  TransitCard copyWith({
    String? id,
    String? alias,
    String? cardTypeLabel,
    String? maskedNumber,
    String? fullMaskedSerial,
    String? lastFour,
    String? holderName,
    String? maskedTckn,
    double? balance,
    CardStatus? status,
    int? subscriptionUsed,
    int? subscriptionTotal,
    String? subscriptionRenewsAt,
    DateTime? lastSyncedAt,
    String? lastStationName,
    DateTime? subscriptionExpiresAt,
  }) {
    return TransitCard(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      cardTypeLabel: cardTypeLabel ?? this.cardTypeLabel,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      fullMaskedSerial: fullMaskedSerial ?? this.fullMaskedSerial,
      lastFour: lastFour ?? this.lastFour,
      holderName: holderName ?? this.holderName,
      maskedTckn: maskedTckn ?? this.maskedTckn,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      subscriptionUsed: subscriptionUsed ?? this.subscriptionUsed,
      subscriptionTotal: subscriptionTotal ?? this.subscriptionTotal,
      subscriptionRenewsAt: subscriptionRenewsAt ?? this.subscriptionRenewsAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastStationName: lastStationName ?? this.lastStationName,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
    );
  }
}
