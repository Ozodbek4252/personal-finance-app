/// Keys on the amount keypad.
sealed class KeypadKey {
  const KeypadKey();
}

/// A digit key. [digits] is "0"–"9" or "000".
class DigitKey extends KeypadKey {
  const DigitKey(this.digits);
  final String digits;
}

class BackspaceKey extends KeypadKey {
  const BackspaceKey();
}

/// The "." key, shown only where cents are allowed (dollars).
class DecimalKey extends KeypadKey {
  const DecimalKey();
}

/// Rules for typing an amount on the keypad. The amount is kept as a
/// string of digits, like "35000", so typing feels natural.
abstract final class AmountInput {
  /// 12 digits is just under one trillion UZS.
  static const maxDigits = 12;

  /// Returns the new digits after pressing [key].
  static String press(String digits, KeypadKey key) {
    switch (key) {
      case BackspaceKey():
        return digits.isEmpty ? digits : digits.substring(0, digits.length - 1);
      case DigitKey(digits: final added):
        // No leading zeros: "0" or "000" on an empty amount does nothing.
        if (digits.isEmpty && int.parse(added) == 0) return digits;
        final next = digits + added;
        return next.length > maxDigits ? digits : next;
      case DecimalKey():
        // So'm have no cents.
        return digits;
    }
  }

  /// Like [press], but for amounts with cents, like "100.50". Allows
  /// one "." and at most two digits after it. Pressing "." first gives
  /// "0.".
  static String pressDecimal(String text, KeypadKey key) {
    final dot = text.indexOf('.');
    switch (key) {
      case BackspaceKey():
        return text.isEmpty ? text : text.substring(0, text.length - 1);
      case DecimalKey():
        if (dot >= 0) return text;
        return text.isEmpty ? '0.' : '$text.';
      case DigitKey(digits: final added):
        if (dot >= 0) {
          final cents = text.length - dot - 1;
          return cents + added.length > 2 ? text : text + added;
        }
        // "0" then "5" gives "5", not "05".
        if (text == '0') text = '';
        if (text.isEmpty && int.parse(added) == 0) return '0';
        final next = text + added;
        return next.length > maxDigits - 2 ? text : next;
    }
  }

  /// "100.5" → 10050 cents. Empty text is 0.
  static int toCents(String text) {
    if (text.isEmpty) return 0;
    final [whole, ...rest] = text.split('.');
    final cents = rest.isEmpty ? '' : rest.first;
    return (whole.isEmpty ? 0 : int.parse(whole)) * 100 +
        int.parse(cents.padRight(2, '0'));
  }

  /// 10050 cents → "100.5", 10000 → "100". The opposite of [toCents],
  /// for going on typing from a worked-out amount.
  static String fromCents(int cents) {
    if (cents == 0) return '';
    final whole = cents ~/ 100;
    final rest = cents % 100;
    if (rest == 0) return '$whole';
    final text = rest.toString().padLeft(2, '0');
    return '$whole.${text.endsWith('0') ? text[0] : text}';
  }

  static int toAmount(String digits) => digits.isEmpty ? 0 : int.parse(digits);
}
