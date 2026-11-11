/// Formatting utilities for Turkish Lira (`₺`) and transit dates.
abstract final class CurrencyFormatter {
  /// Formats a double amount in Turkish Lira format (`₺245,50` or `+₺150,00` / `-₺20,00`).
  static String formatTl(
    double amount, {
    bool showSign = false,
    bool compactDecimals = false,
  }) {
    final absVal = amount.abs();
    final whole = absVal.truncate();
    final cents = ((absVal - whole) * 100).round();

    final wholeStr = _formatThousands(whole);
    final centsStr = cents.toString().padLeft(2, '0');

    final prefix = showSign
        ? (amount > 0 ? '+₺' : (amount < 0 ? '-₺' : '₺'))
        : (amount < 0 ? '-₺' : '₺');

    if (compactDecimals && cents == 0) {
      return '$prefix$wholeStr';
    }
    return '$prefix$wholeStr,$centsStr';
  }

  /// Splits an amount into whole and decimal parts for the hero card display
  /// (`245` and `,50`).
  static ({String whole, String decimal}) splitParts(double amount) {
    final absVal = amount.abs();
    final whole = absVal.truncate();
    final cents = ((absVal - whole) * 100).round();
    return (
      whole: _formatThousands(whole),
      decimal: ',${cents.toString().padLeft(2, '0')}',
    );
  }

  static String _formatThousands(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

