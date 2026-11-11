import 'dart:convert';
import 'package:hive_ce/hive.dart';

import 'cache_keys.dart';

/// Abstract contract for reading and writing JSON-serializable structures
/// into the local Hive CE cache.
abstract interface class LocalCacheDataSource {
  Map<String, dynamic>? readMap(String key);
  List<Map<String, dynamic>> readList(String key);
  bool readBool(String key, {bool defaultValue = false});
  String? readString(String key);

  Future<void> writeMap(String key, Map<String, dynamic>? value);
  Future<void> writeList(String key, List<Map<String, dynamic>> value);
  Future<void> writeBool(String key, bool value);
  Future<void> writeString(String key, String? value);
  Future<void> remove(String key);
  Future<void> clearAllAndReseed({bool keepAuth = false});
  Future<void> ensureSeeded();
}

/// Hive CE implementation of [LocalCacheDataSource].
class HiveCacheDataSource implements LocalCacheDataSource {
  HiveCacheDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Map<String, dynamic>? readMap(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    if (raw is String) {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  @override
  List<Map<String, dynamic>> readList(String key) {
    final raw = _box.get(key);
    if (raw == null) return <Map<String, dynamic>>[];
    if (raw is String) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (raw is List) {
      return raw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  @override
  bool readBool(String key, {bool defaultValue = false}) {
    final raw = _box.get(key);
    if (raw is bool) return raw;
    return defaultValue;
  }

  @override
  String? readString(String key) {
    final raw = _box.get(key);
    return raw is String ? raw : null;
  }

  @override
  Future<void> writeMap(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, jsonEncode(value));
  }

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _box.put(key, jsonEncode(value));
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> writeString(String key, String? value) async {
    if (value == null) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clearAllAndReseed({bool keepAuth = false}) async {
    final savedUser = keepAuth ? readMap(CacheKeys.currentUser) : null;
    final savedUsers = readList(CacheKeys.registeredUsers);
    await _box.clear();
    await SeedData.apply(this);
    if (savedUsers.isNotEmpty) {
      await writeList(CacheKeys.registeredUsers, savedUsers);
    }
    if (keepAuth && savedUser != null) {
      await writeMap(CacheKeys.currentUser, savedUser);
    } else if (!keepAuth) {
      await remove(CacheKeys.currentUser);
    }
  }

  @override
  Future<void> ensureSeeded() async {
    final seeded = readBool(CacheKeys.isSeeded);
    if (!seeded) {
      await SeedData.apply(this);
      return;
    }
    if (!readBool('v3_abonman_260_rule')) {
      final cards = readList(CacheKeys.transitCards);
      final updated = cards.map((map) {
        if (map['id'] == 'card_mavihat_4821') {
          return <String, dynamic>{
            ...map,
            'subscriptionUsed': 199,
            'subscriptionTotal': 200,
            'subscriptionRenewsAt': '15 Kasım 2026',
            'subscriptionExpiresAtIso': '2026-11-15T23:59:59.000Z',
          };
        }
        return map;
      }).toList();
      await writeList(CacheKeys.transitCards, updated);
      await writeBool('v3_abonman_260_rule', true);
    }
  }
}

/// In-memory implementation of [LocalCacheDataSource] for fast, deterministic
/// unit and widget testing without disk I/O locks.
class InMemoryCacheDataSource implements LocalCacheDataSource {
  final Map<String, dynamic> _store = <String, dynamic>{};

  @override
  Map<String, dynamic>? readMap(String key) {
    final raw = _store[key];
    if (raw == null) return null;
    if (raw is String) {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  @override
  List<Map<String, dynamic>> readList(String key) {
    final raw = _store[key];
    if (raw == null) return <Map<String, dynamic>>[];
    if (raw is String) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (raw is List) {
      return raw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  @override
  bool readBool(String key, {bool defaultValue = false}) {
    final raw = _store[key];
    return raw is bool ? raw : defaultValue;
  }

  @override
  String? readString(String key) {
    final raw = _store[key];
    return raw is String ? raw : null;
  }

  @override
  Future<void> writeMap(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      _store.remove(key);
      return;
    }
    _store[key] = jsonEncode(value);
  }

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    _store[key] = jsonEncode(value);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    _store[key] = value;
  }

  @override
  Future<void> writeString(String key, String? value) async {
    if (value == null) {
      _store.remove(key);
      return;
    }
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clearAllAndReseed({bool keepAuth = false}) async {
    final savedUser = keepAuth ? readMap(CacheKeys.currentUser) : null;
    _store.clear();
    await SeedData.apply(this);
    if (keepAuth && savedUser != null) {
      await writeMap(CacheKeys.currentUser, savedUser);
    } else if (!keepAuth) {
      await remove(CacheKeys.currentUser);
    }
  }

  @override
  Future<void> ensureSeeded() async {
    if (!readBool(CacheKeys.isSeeded)) {
      await SeedData.apply(this);
    }
  }
}

/// Canonical Istanbul MaviHat seed data matching all 31 Stitch screens.
abstract final class SeedData {
  static Future<void> apply(LocalCacheDataSource ds) async {
    final defaultUser = <String, dynamic>{
      'uid': 'usr_shahd_4821',
      'email': 'shahd.kassem@mavihat.istanbul',
      'displayName': 'Shahd Mohamed Kassem',
      'phoneNumber': '+90 532 418 90 42',
      'tcknMasked': '*******1234',
      'tcknProfileMasked': '180******42',
      'createdAt': '2024-09-01T09:00:00.000Z',
      'isPhoneVerified': true,
    };

    await ds.writeMap(CacheKeys.currentUser, defaultUser);
    await ds.writeList(CacheKeys.registeredUsers, <Map<String, dynamic>>[
      {
        ...defaultUser,
        'passwordHash': 'Demo1234!',
      },
    ]);

    await ds.writeString(CacheKeys.activeCardId, 'card_mavihat_4821');

    await ds.writeList(CacheKeys.transitCards, <Map<String, dynamic>>[
      {
        'id': 'card_mavihat_4821',
        'alias': 'İstanbul Şehir Kartı',
        'cardTypeLabel': 'KİŞİSEL TAM KART',
        'maskedNumber': '•••• 4821',
        'fullMaskedSerial': 'MH-••••-4821',
        'lastFour': '4821',
        'holderName': 'SHAHD MOHAMED KASSEM',
        'maskedTckn': '*******1234',
        'balance': 245.50,
        'status': 'active',
        'subscriptionUsed': 199,
        'subscriptionTotal': 200,
        'subscriptionRenewsAt': '15 Kasım 2026',
        'subscriptionExpiresAtIso': '2026-11-15T23:59:59.000Z',
        'lastSyncedAt': '2026-10-24T18:42:00.000Z',
        'lastStationName': 'Kadıköy İskelesi',
      },
    ]);

    await ds.writeList(CacheKeys.paymentMethods, <Map<String, dynamic>>[
      {
        'id': 'pm_troy_4821',
        'brand': 'TROY',
        'bankName': 'Ziraat Bankası Banka Kartı',
        'lastFour': '4821',
        'expiryMonth': 8,
        'expiryYear': 28,
        'cardholderName': 'SHAHD MOHAMED KASSEM',
        'isDefault': true,
        'providerTokenReference': 'tok_sandbox_troy_4821',
      },
      {
        'id': 'pm_mc_9012',
        'brand': 'Mastercard',
        'bankName': 'İş Bankası Maximum Kredi Kartı',
        'lastFour': '9012',
        'expiryMonth': 11,
        'expiryYear': 27,
        'cardholderName': 'SHAHD MOHAMED KASSEM',
        'isDefault': false,
        'providerTokenReference': 'tok_sandbox_mc_9012',
      },
    ]);

    await ds.writeList(CacheKeys.transactions, <Map<String, dynamic>>[
      {
        'id': 'txn_kadikoy_94820',
        'referenceCode': 'TXN-20261024-94820',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Kadıköy İskelesi',
        'subtitle': 'Şehir Hatları • Eminönü - Kadıköy Vapur Hattı',
        'lineCode': 'Şehir Hatları • Kadıköy - Eminönü',
        'validatorCode': 'VLD-KDK-04 (Turnike #4)',
        'tariffType': 'Tam Biniş Sabit Tarifesi',
        'category': 'ferry',
        'type': 'fare',
        'amount': -20.00,
        'balanceAfter': 245.50,
        'timestampIso': '2026-10-24T18:42:00.000Z',
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '18:42',
        'latitude': 40.9912,
        'longitude': 29.0228,
        'status': 'completed',
      },
      {
        'id': 'txn_topup_88310',
        'referenceCode': 'TXN-20261024-88310',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Bakiye Yükleme',
        'subtitle': 'TROY •••• 4821 • Mobil Uygulama',
        'lineCode': 'Mobil Dolum • Anında Bakiye',
        'validatorCode': 'MVH-ONL-01 (Sanal POS)',
        'tariffType': 'Dijital Bakiye Dolumu',
        'category': 'topUp',
        'type': 'topUp',
        'amount': 200.00,
        'balanceAfter': 273.00,
        'timestampIso': '2026-10-24T14:15:00.000Z',
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '14:15',
        'latitude': 41.0082,
        'longitude': 28.9784,
        'status': 'completed',
      },
      {
        'id': 'txn_yenikapi_77102',
        'referenceCode': 'TXN-20261024-77102',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Yenikapı M2 İstasyonu',
        'subtitle': 'M2 Yenikapı - Hacıosman Metro',
        'lineCode': 'M2 Yenikapı - Hacıosman Metro',
        'validatorCode': 'VLD-YNK-12 (Kuzey Turnike #2)',
        'tariffType': 'Tam Biniş Tarifesi',
        'category': 'metro',
        'type': 'fare',
        'amount': -20.00,
        'balanceAfter': 73.00,
        'timestampIso': '2026-10-24T08:42:00.000Z',
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '08:42',
        'latitude': 41.0054,
        'longitude': 28.9519,
        'status': 'completed',
      },
      {
        'id': 'txn_iett_76401',
        'referenceCode': 'TXN-20261024-76401',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'İETT 78 • Eminönü Durağı',
        'subtitle': 'Otobüs • Aktarma İndirimi (1. Kademe)',
        'lineCode': 'İETT 78 Başakşehir - Eminönü',
        'validatorCode': 'VLD-BUS-3478 (Araç İçi #1)',
        'tariffType': '1. Aktarma İndirimli Biniş',
        'category': 'bus',
        'type': 'fare',
        'amount': -14.32,
        'balanceAfter': 93.00,
        'timestampIso': '2026-10-24T08:15:00.000Z',
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '08:15',
        'latitude': 41.0168,
        'longitude': 28.9708,
        'status': 'completed',
      },
      {
        'id': 'txn_karakoy_65019',
        'referenceCode': 'TXN-20261023-65019',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Karaköy İskelesi',
        'subtitle': 'Şehir Hatları • Kadıköy - Karaköy',
        'lineCode': 'Şehir Hatları • Kadıköy - Karaköy',
        'validatorCode': 'VLD-KRK-02 (Turnike #2)',
        'tariffType': 'Tam Biniş Tarifesi (Deniz Ulaşımı)',
        'category': 'ferry',
        'type': 'fare',
        'amount': -27.50,
        'balanceAfter': 107.32,
        'timestampIso': '2026-10-23T19:10:00.000Z',
        'displayDateGroup': 'DÜN, 23 EKİM',
        'displayTime': '19:10',
        'latitude': 41.0221,
        'longitude': 28.9762,
        'status': 'completed',
      },
      {
        'id': 'txn_marmaray_54901',
        'referenceCode': 'TXN-20261023-54901',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Marmaray Sirkeci İstasyonu',
        'subtitle': 'B1 Halkalı - Gebze Banliyö Hattı',
        'lineCode': 'Marmaray B1 • Sirkeci',
        'validatorCode': 'VLD-MRM-08 (Cağaloğlu Girişi)',
        'tariffType': '1-7 İstasyon Tam Parkur',
        'category': 'metro',
        'type': 'fare',
        'amount': -20.00,
        'balanceAfter': 134.82,
        'timestampIso': '2026-10-23T09:05:00.000Z',
        'displayDateGroup': 'DÜN, 23 EKİM',
        'displayTime': '09:05',
        'latitude': 41.0132,
        'longitude': 28.9773,
        'status': 'completed',
      },
      {
        'id': 'txn_besiktas_41209',
        'referenceCode': 'TXN-20261021-41209',
        'cardId': 'card_mavihat_4821',
        'maskedCardNumber': '•••• 4821',
        'title': 'Beşiktaş Meydan Durağı (28T)',
        'subtitle': 'İETT Otobüs • Topkapı - Beşiktaş',
        'lineCode': 'İETT 28T Topkapı - Beşiktaş',
        'validatorCode': 'VLD-BUS-2810 (Araç İçi #1)',
        'tariffType': 'Tam Biniş Tarifesi',
        'category': 'bus',
        'type': 'fare',
        'amount': -20.00,
        'balanceAfter': 154.82,
        'timestampIso': '2026-10-21T17:40:00.000Z',
        'displayDateGroup': '21 EKİM PAZARTESİ',
        'displayTime': '17:40',
        'latitude': 41.0422,
        'longitude': 29.0067,
        'status': 'completed',
      },
      {
        'id': 'txn_student_1001',
        'referenceCode': 'TXN-20261024-10010',
        'cardId': 'card_student_1092',
        'maskedCardNumber': '•••• 1092',
        'title': 'Vezneciler M2 İstasyonu',
        'subtitle': 'M2 Metro • Öğrenci Tarifesi',
        'lineCode': 'M2 Yenikapı - Hacıosman Metro',
        'validatorCode': 'VLD-VZN-03 (Üniversite Çıkışı)',
        'tariffType': 'Öğrenci İndirimli Biniş',
        'category': 'metro',
        'type': 'fare',
        'amount': -9.76,
        'balanceAfter': 42.00,
        'timestampIso': '2026-10-24T13:20:00.000Z',
        'displayDateGroup': 'BUGÜN, 24 EKİM',
        'displayTime': '13:20',
        'latitude': 41.0122,
        'longitude': 28.9598,
        'status': 'completed',
      },
    ]);

    await ds.writeMap(CacheKeys.userPreferences, <String, dynamic>{
      'themeMode': 'light',
      'localeCode': 'tr',
      'onboardingCompleted': true,
      'highContrast': false,
      'biometricEnabled': true,
      'twoFactorEnabled': true,
      'transitAlertsEnabled': true,
      'lowBalanceAlertsEnabled': true,
      'promoAlertsEnabled': false,
      'proximityServiceEnabled': true,
      'autoTopUpEnabled': false,
      'autoTopUpThreshold': 50.0,
      'autoTopUpAmount': 150.0,
      'cacheSizeMb': 14.2,
    });

    await ds.writeList(
      CacheKeys.bookmarkedArticles,
      <Map<String, dynamic>>[],
    );
    await ds.writeBool(CacheKeys.isSeeded, true);
    await ds.writeBool('v3_abonman_260_rule', true);
  }
}

