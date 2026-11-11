import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/map_entities.dart';
import '../repositories/map_repository.dart';

class GetLastTransactionLocation {
  const GetLastTransactionLocation(this._repository);

  final MapRepository _repository;

  Future<Result<LastTransactionLocation>> call(String cardId) =>
      _repository.getLastTransactionLocation(cardId);

  LastTransactionLocation sync(String cardId) =>
      _repository.getLastTransactionLocationSync(cardId);
}

class GetNearbyTransitStops {
  const GetNearbyTransitStops(this._repository);

  final MapRepository _repository;

  Future<Result<List<TransitStop>>> call({
    StopCategory? category,
    String query = '',
  }) =>
      _repository.getNearbyStops(category: category, query: query);

  List<TransitStop> sync({
    StopCategory? category,
    String query = '',
  }) =>
      _repository.getNearbyStopsSync(category: category, query: query);
}

class GetDeviceLocation {
  const GetDeviceLocation(this._service);

  final DeviceLocationService _service;

  Future<Result<DeviceLocationState>> call() =>
      _service.requestDeviceLocation();
}

class ReportLocationDiscrepancy {
  const ReportLocationDiscrepancy(this._repository);

  final MapRepository _repository;

  Future<Result<void>> call({
    required String transactionId,
    required String note,
  }) async {
    if (note.trim().length < 4) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen konum tutarsızlığını kısaca açıklayın.',
        ),
      );
    }
    return _repository.reportLocationDiscrepancy(
      transactionId: transactionId,
      note: note.trim(),
    );
  }
}

