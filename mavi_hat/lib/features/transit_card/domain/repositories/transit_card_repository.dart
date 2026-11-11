import '../../../../core/utils/result.dart';
import '../entities/transit_card.dart';

/// Abstract repository for managing MaviHat transit cards, lock state,
/// monthly subscription loading, and NFC/QR turnstile validations.
abstract interface class TransitCardRepository {
  TransitCard getActiveCardSync();

  List<TransitCard> getUserCardsSync();

  Future<Result<TransitCard>> getActiveCard();

  Future<Result<List<TransitCard>>> getUserCards();

  Future<Result<TransitCard>> selectActiveCard(String cardId);

  Future<Result<TransitCard>> lockCard({
    required String cardId,
    required bool reportStolenTo153,
    String? reason,
  });

  Future<Result<TransitCard>> unlockCard({
    required String cardId,
    required String otpCode,
  });

  Future<Result<TransitCard>> pairPhysicalCard({
    required String serialLastFour,
    required String alias,
  });

  Future<Result<TransitCard>> loadSubscription({
    required String cardId,
    required int addedPasses,
    required double price,
    required String packageTitle,
    required String paymentMethodLabel,
  });

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
  });
}

/// Abstract service for evaluating NFC / Contactless turnstile eligibility.
abstract interface class TransitCredentialService {
  NfcEligibilityStatus checkEligibility(TransitCard card);
}
