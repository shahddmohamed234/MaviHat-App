import '../../../../core/utils/result.dart';
import '../entities/map_entities.dart';

/// Abstract repository for retrieving the card's last transaction station
/// and nearby Istanbul transit stops.
abstract interface class MapRepository {
  LastTransactionLocation getLastTransactionLocationSync(String cardId);

  List<TransitStop> getNearbyStopsSync({
    StopCategory? category,
    String query = '',
  });

  Future<Result<LastTransactionLocation>> getLastTransactionLocation(
    String cardId,
  );

  Future<Result<List<TransitStop>>> getNearbyStops({
    StopCategory? category,
    String query = '',
  });

  Future<Result<void>> reportLocationDiscrepancy({
    required String transactionId,
    required String note,
  });
}

/// Abstract service for retrieving the phone's own location (with permission).
abstract interface class DeviceLocationService {
  Future<Result<DeviceLocationState>> requestDeviceLocation();
}

