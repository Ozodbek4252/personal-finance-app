import 'package:flutter/services.dart';

import 'money_format.dart';

/// Keeps only digits in an amount field and shows them grouped,
/// like "420 000". The cursor stays at the end.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = digits.isEmpty ? '' : MoneyFormat.amount(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
