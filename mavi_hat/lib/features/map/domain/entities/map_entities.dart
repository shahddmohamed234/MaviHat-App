enum StopCategory {
  lastTransaction,
  ferry,
  tram,
  metro,
}

/// Represents the last validator station location where the card was tapped.
///
/// Explicitly distinct from live GPS tracking of the physical card (`project.md`).
class LastTransactionLocation {
  const LastTransactionLocation({
    required this.transactionId,
    required this.cardMaskedNumber,
    required this.stationName,
    required this.lineDescription,
    required this.validatorCode,
    required this.amountDeducted,
    required this.timestampLabel,
    required this.latitude,
    required this.longitude,
    required this.walkingDistanceLabel,
    this.category = 'ferry',
  });

  final String transactionId;
  final String cardMaskedNumber;
  final String stationName;
  final String lineDescription;
  final String validatorCode;
  final double amountDeducted;
  final String timestampLabel;
  final double latitude;
  final double longitude;
  final String walkingDistanceLabel;
  final String category;
}

/// Represents an Istanbul transit stop or pier shown on the map.
class TransitStop {
  const TransitStop({
    required this.id,
    required this.name,
    required this.lineSummary,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.hasTopUpKiosk,
  });

  final String id;
  final String name;
  final String lineSummary;
  final StopCategory category;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final bool hasTopUpKiosk;
}

/// Represents the user's phone GPS location state (distinct from card validator log).
class DeviceLocationState {
  const DeviceLocationState({
    required this.hasPermission,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final bool hasPermission;
  final double latitude;
  final double longitude;
  final String label;
}

