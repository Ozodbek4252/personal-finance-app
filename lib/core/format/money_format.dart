/// How thousands are grouped: "15 000 000", "15,000,000" or "15.000.000".
/// Chosen in Settings > Number format.
enum NumberStyle {
  space('\u00A0'),
  comma(','),
  dot('.');

  const NumberStyle(this.separator);
  final String separator;

  /// Example shown in Settings.
  String get example => '15${separator}000${separator}000';
}

/// Formats money amounts the way the design shows them.
///
/// Amounts are whole UZS stored as [int]. We never use doubles for money.
abstract final class MoneyFormat {
  /// Set from Settings when the app starts and when the setting changes.
  static NumberStyle style = NumberStyle.space;

  /// Non-breaking space. Keeps "12 450 000" on one line.
  static const nbsp = ' ';

  /// Real minus sign (−), not a hyphen (-).
  static const minus = '−';

  static const currency = 'UZS';

  /// 12450000 → "12 450 000". Negative values get "−".
  static String amount(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(style.separator);
      }
      buffer.write(digits[i]);
    }
    return value < 0 ? '$minus$buffer' : buffer.toString();
  }

  /// Like [amount], but always shows a sign: "+15 000 000", "−420 000".
  /// Zero has no sign.
  static String signed(int value) {
    if (value > 0) return '+${amount(value)}';
    return amount(value);
  }

  /// 820000 → "820 000 UZS".
  static String withCurrency(int value) => '${amount(value)}$nbsp$currency';

  /// Short form for charts: 14500000 → "14.5M", 3000000 → "3M",
  /// 850000 → "850K". Set [showSign] to add "+" or "−".
  static String compact(int value, {bool showSign = false}) {
    final abs = value.abs();
    final String body;
    if (abs >= 1000000) {
      body = '${_trim(abs / 1000000)}M';
    } else if (abs >= 1000) {
      body = '${_trim(abs / 1000)}K';
    } else {
      body = abs.toString();
    }
    if (value < 0) return '$minus$body';
    if (showSign && value > 0) return '+$body';
    return body;
  }

  /// An exchange rate: 12650 → "12 650", 11778.45 → "11 778.45".
  /// Decimals show only when there are any. With the dot number style
  /// the decimal mark is a comma: "11.778,45".
  static String rate(double value) {
    final cents = (value * 100).round();
    final whole = amount(cents ~/ 100);
    final rest = cents % 100;
    if (rest == 0) return whole;
    final mark = style == NumberStyle.dot ? ',' : '.';
    return '$whole$mark${rest.toString().padLeft(2, '0')}';
  }

  /// Turns raw keypad input ("35000") into an int. Empty input is 0.
  static int parseDigits(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  /// One decimal place, without a trailing ".0": 14.5 → "14.5", 3.0 → "3".
  /// Rounds like the design does: 3.05 → "3" (the double is 3.0499…).
  static String _trim(double v) {
    final text = v.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

/// Formats percentages and percentage-point changes.
abstract final class PercentFormat {
  /// 27.0 → "27%", 3.3 → "3.3%". Use [decimals] to fix the digits.
  static String value(double percent, {int? decimals}) {
    final text = decimals == null
        ? _auto(percent.abs())
        : percent.abs().toStringAsFixed(decimals);
    return percent < 0 ? '${MoneyFormat.minus}$text%' : '$text%';
  }

  /// Change with a sign: "+3.3%", "−28.7%", "±0.0%".
  static String change(double percent) {
    final text = percent.abs().toStringAsFixed(1);
    if (text == '0.0') return '±0.0%';
    return percent > 0 ? '+$text%' : '${MoneyFormat.minus}$text%';
  }

  /// Change in percentage points: "+8.9 pts", "−1.6 pts".
  static String points(double points) {
    final text = points.abs().toStringAsFixed(1);
    if (text == '0.0') return '±0.0 pts';
    return points > 0 ? '+$text pts' : '${MoneyFormat.minus}$text pts';
  }

  /// Whole number when the value is whole, else one decimal place.
  static String _auto(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
  }
}
