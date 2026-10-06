/// Reading and writing exchange rates in text fields.
abstract final class RateInput {
  /// "12 650.5", "12,650.5" or "12650,5" → 12650.5. Null when the text
  /// is not a positive number.
  static double? parse(String text) {
    var t = text.trim().replaceAll(' ', '').replaceAll(' ', '');
    // A single comma with no dot is a decimal mark ("12650,37").
    if (!t.contains('.') && ','.allMatches(t).length == 1) {
      t = t.replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
    final rate = double.tryParse(t);
    return rate != null && rate > 0 && rate.isFinite ? rate : null;
  }

  /// 12650.0 → "12650", 11778.45 → "11778.45". For an edit field.
  static String plain(double rate) => rate == rate.roundToDouble()
      ? '${rate.round()}'
      : rate.toStringAsFixed(2);
}
