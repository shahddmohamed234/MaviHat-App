import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/result.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transit_transaction.dart';
import '../../domain/entities/map_entities.dart';
import '../../domain/repositories/map_repository.dart';

/// Implementation of [MapRepository] deriving the card's last transaction
/// station from validator transaction records (`Son İşlem Noktası`), never
/// claiming live GPS tracking of the physical card.
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  static const List<TransitStop> _istanbulStops = <TransitStop>[
    TransitStop(
      id: 'stop_kadikoy_iskelesi',
      name: 'Kadıköy İskelesi (Şehir Hatları)',
      lineSummary: 'Eminönü • Karaköy • Beşiktaş • Adalar Vapur Hatları',
      category: StopCategory.ferry,
      latitude: 40.9912,
      longitude: 29.0228,
      distanceMeters: 45,
      hasTopUpKiosk: true,
    ),
    TransitStop(
      id: 'stop_kadikoy_m4',
      name: 'Kadıköy M4 Metro İstasyonu',
      lineSummary: 'M4 Kadıköy - Sabiha Gökçen Havalimanı Metro Hattı',
      category: StopCategory.metro,
      latitude: 40.9905,
      longitude: 29.0239,
      distanceMeters: 120,
      hasTopUpKiosk: true,
    ),
    TransitStop(
      id: 'stop_kadikoy_t3',
      name: 'Kadıköy İskele T3 Nostaljik Tramvay',
      lineSummary: 'T3 Kadıköy - Moda Ring Tramvay Hattı',
      category: StopCategory.tram,
      latitude: 40.9901,
      longitude: 29.0246,
      distanceMeters: 165,
      hasTopUpKiosk: false,
    ),
    TransitStop(
      id: 'stop_karakoy_iskelesi',
      name: 'Karaköy Vapur İskelesi',
      lineSummary: 'Şehir Hatları • Kadıköy - Karaköy - Eminönü',
      category: StopCategory.ferry,
      latitude: 41.0221,
      longitude: 28.9762,
      distanceMeters: 4200,
      hasTopUpKiosk: true,
    ),
    TransitStop(
      id: 'stop_karakoy_f2',
      name: 'Karaköy F2 Tarihi Tünel & T1 Tramvay',
      lineSummary: 'F2 Karaköy - Beyoğlu Tünel • T1 Kabataş - Bağcılar',
      category: StopCategory.tram,
      latitude: 41.0228,
      longitude: 28.9746,
      distanceMeters: 4350,
      hasTopUpKiosk: true,
    ),
    TransitStop(
      id: 'stop_yenikapi_m2',
      name: 'Yenikapı M1/M2 & Marmaray Aktarma Merkezi',
      lineSummary: 'M2 Hacıosman • M1A/M1B • Marmaray B1',
      category: StopCategory.metro,
      latitude: 41.0054,
      longitude: 28.9519,
      distanceMeters: 5800,
      hasTopUpKiosk: true,
    ),
    TransitStop(
      id: 'stop_besiktas_iskelesi',
      name: 'Beşiktaş Vapur İskelesi',
      lineSummary: 'Şehir Hatları • Kadıköy - Beşiktaş - Üsküdar',
      category: StopCategory.ferry,
      latitude: 41.0415,
      longitude: 29.0074,
      distanceMeters: 6100,
      hasTopUpKiosk: true,
    ),
  ];

  @override
  LastTransactionLocation getLastTransactionLocationSync(String cardId) {
    final rawTxns = _cache.readList(CacheKeys.transactions);
    final txns = rawTxns.map(TransactionRepositoryImpl.mapToTransaction).toList();

    final fareTxns = txns
        .where((t) => t.cardId == cardId && t.type == TransactionType.fare)
        .toList();
    final target = fareTxns.isNotEmpty
        ? fareTxns.first
        : (txns.isNotEmpty ? txns.first : null);

    if (target != null) {
      return LastTransactionLocation(
        transactionId: target.id,
        cardMaskedNumber: target.maskedCardNumber,
        stationName: target.title,
        lineDescription: target.lineCode,
        validatorCode: target.validatorCode,
        amountDeducted: target.amount,
        timestampLabel: 'Bugün, ${target.displayTime}',
        latitude: target.latitude,
        longitude: target.longitude,
        walkingDistanceLabel: 'Turnike çıkışı • Peron Çıkışı',
        category: target.category,
      );
    }

    return const LastTransactionLocation(
      transactionId: 'txn_kadikoy_94820',
      cardMaskedNumber: '•••• 4821',
      stationName: 'Kadıköy İskelesi',
      lineDescription: 'Şehir Hatları • Kadıköy - Eminönü',
      validatorCode: 'VLD-KDK-04 (Turnike #4)',
      amountDeducted: -27.50,
      timestampLabel: 'Bugün, 18:42',
      latitude: 40.9912,
      longitude: 29.0228,
      walkingDistanceLabel: 'Turnike çıkışı • Rıhtım Peron 2',
    );
  }

  @override
  Future<Result<LastTransactionLocation>> getLastTransactionLocation(
    String cardId,
  ) async {
    return Success(getLastTransactionLocationSync(cardId));
  }

  @override
  List<TransitStop> getNearbyStopsSync({
    StopCategory? category,
    String query = '',
  }) {
    var list = _istanbulStops;
    if (category != null && category != StopCategory.lastTransaction) {
      list = list.where((s) => s.category == category).toList();
    }
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.name.toLowerCase().contains(cleanQuery) ||
                s.lineSummary.toLowerCase().contains(cleanQuery),
          )
          .toList();
    }
    return list;
  }

  @override
  Future<Result<List<TransitStop>>> getNearbyStops({
    StopCategory? category,
    String query = '',
  }) async {
    return Success(getNearbyStopsSync(category: category, query: query));
  }

  @override
  Future<Result<void>> reportLocationDiscrepancy({
    required String transactionId,
    required String note,
  }) async {
    final existing = _cache.readList(CacheKeys.locationReports);
    await _cache.writeList(
      CacheKeys.locationReports,
      <Map<String, dynamic>>[
        ...existing,
        <String, dynamic>{
          'id': 'loc_rep_${DateTime.now().millisecondsSinceEpoch}',
          'transactionId': transactionId,
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ],
    );
    return const Success(null);
  }
}

/// Permission-based device location service returning the user's phone
/// coordinates in Kadıköy Rıhtım Meydanı (clearly distinct from the card's
/// validator tap log).
class PrototypeDeviceLocationService implements DeviceLocationService {
  const PrototypeDeviceLocationService();

  @override
  Future<Result<DeviceLocationState>> requestDeviceLocation() async {
    return const Success(
      DeviceLocationState(
        hasPermission: true,
        latitude: 40.9924,
        longitude: 29.0241,
        label: 'Telefon Konumunuz: Kadıköy Rıhtım Caddesi (±12m)',
      ),
    );
  }
}

