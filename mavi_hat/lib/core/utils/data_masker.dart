/// Masking utilities for sensitive personal and financial identifiers.
///
/// Enforces the mandatory security rule that full TCKN or full PAN is never
/// exposed on card faces or stored in plain text.
abstract final class DataMasker {
  /// Masks an 11-digit Turkish National ID (TCKN), exposing at most the last 4
  /// or prefix + last 2 digits while never returning an unmasked 11-digit string.
  static String maskTckn(String rawOrLastFour, {String prefix = '180'}) {
    final digits = rawOrLastFour.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '*******1234';
    }
    if (digits.length <= 4) {
      final padded = digits.padLeft(4, '0');
      return '*******$padded';
    }
    final lastFour = digits.substring(digits.length - 4);
    return '*******$lastFour';
  }

  /// Masks TCKN in the profile pill format (`180******42`).
  static String maskTcknProfile(String lastFour, {String prefix = '180'}) {
    final clean = lastFour.replaceAll(RegExp(r'[^0-9]'), '');
    final lastTwo = clean.length >= 2
        ? clean.substring(clean.length - 2)
        : clean.padLeft(2, '0');
    return '$prefix******$lastTwo';
  }

  /// Masks a transit card number (`•••• 4821` or `MH-••••-4821`).
  static String maskCardNumber(String lastFour, {bool includePrefix = false}) {
    final clean = lastFour.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = clean.length >= 4
        ? clean.substring(clean.length - 4)
        : clean.padLeft(4, '0');
    return includePrefix ? 'MH-••••-$suffix' : '•••• $suffix';
  }

  /// Masks a payment card number (`•••• •••• •••• 4821`).
  static String maskPaymentPan(String rawOrLastFour) {
    final digits = rawOrLastFour.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits.padLeft(4, '0');
    return '•••• •••• •••• $suffix';
  }

  /// Masks a Turkish phone number (`+90 532 ••• •• 42`).
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return '+90 532 ••• •• 42';
    }
    final lastTwo = digits.substring(digits.length - 2);
    String operatorCode = '532';
    if (digits.length >= 10) {
      final tenDigits = digits.substring(digits.length - 10);
      operatorCode = tenDigits.substring(0, 3);
    }
    return '+90 $operatorCode ••• •• $lastTwo';
  }

  /// Extracts only the last 4 digits from a payment card number input.
  static String extractLastFour(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return digits.padLeft(4, '0');
    }
    return digits.substring(digits.length - 4);
  }
}

