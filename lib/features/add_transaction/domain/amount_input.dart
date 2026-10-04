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
    }
  }

  static int toAmount(String digits) => digits.isEmpty ? 0 : int.parse(digits);
}
