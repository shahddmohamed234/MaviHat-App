import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/transit_card.dart';
import '../repositories/transit_card_repository.dart';

class GetTransitCard {
  const GetTransitCard(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call() => _repository.getActiveCard();
  TransitCard sync() => _repository.getActiveCardSync();
}

class GetUserCards {
  const GetUserCards(this._repository);

  final TransitCardRepository _repository;

  Future<Result<List<TransitCard>>> call() => _repository.getUserCards();
  List<TransitCard> sync() => _repository.getUserCardsSync();
}

class SelectActiveCard {
  const SelectActiveCard(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call(String cardId) =>
      _repository.selectActiveCard(cardId);
}

class LockTransitCard {
  const LockTransitCard(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call({
    required String cardId,
    bool reportStolenTo153 = false,
    String? reason,
  }) {
    return _repository.lockCard(
      cardId: cardId,
      reportStolenTo153: reportStolenTo153,
      reason: reason,
    );
  }
}

class UnlockTransitCard {
  const UnlockTransitCard(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call({
    required String cardId,
    required String otpCode,
  }) async {
    final clean = otpCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 6) {
      return const Err(
        ValidationFailure(
          message: 'Kilit kaldırma işlemi için 6 haneli SMS kodunu girin.',
        ),
      );
    }
    return _repository.unlockCard(cardId: cardId, otpCode: clean);
  }
}

class PairPhysicalCard {
  const PairPhysicalCard(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call({
    required String serialNumber,
    required String alias,
  }) async {
    final digits = serialNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return const Err(
        ValidationFailure(
          message:
              'Lütfen ulaşım kartınızın en az 4 haneli seri numarasını girin.',
        ),
      );
    }
    if (alias.trim().length < 2) {
      return const Err(
        ValidationFailure(message: 'Lütfen kart için geçerli bir rumuz girin.'),
      );
    }
    final lastFour = digits.substring(digits.length - 4);
    return _repository.pairPhysicalCard(
      serialLastFour: lastFour,
      alias: alias.trim(),
    );
  }
}

class LoadSubscription {
  const LoadSubscription(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call({
    required String cardId,
    required int addedPasses,
    required double price,
    required String packageTitle,
    required String paymentMethodLabel,
  }) {
    return _repository.loadSubscription(
      cardId: cardId,
      addedPasses: addedPasses,
      price: price,
      packageTitle: packageTitle,
      paymentMethodLabel: paymentMethodLabel,
    );
  }
}

class ExecuteTurnstilePass {
  const ExecuteTurnstilePass(this._repository);

  final TransitCardRepository _repository;

  Future<Result<TransitCard>> call({
    required String cardId,
    String stationName = '',
    String lineDescription = '',
    String category = 'metro',
    required double fareAmount,
    required String methodLabel,
    double latitude = 41.0082,
    double longitude = 28.9784,
    bool useSubscription = false,
  }) {
    return _repository.executeTurnstilePass(
      cardId: cardId,
      stationName: stationName,
      lineDescription: lineDescription,
      category: category,
      fareAmount: fareAmount,
      methodLabel: methodLabel,
      latitude: latitude,
      longitude: longitude,
      useSubscription: useSubscription,
    );
  }
}

class CheckNfcEligibility {
  const CheckNfcEligibility(this._service);

  final TransitCredentialService _service;

  NfcEligibilityStatus call(TransitCard card) =>
      _service.checkEligibility(card);
}
