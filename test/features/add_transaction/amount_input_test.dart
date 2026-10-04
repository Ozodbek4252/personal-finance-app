import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/add_transaction/domain/amount_input.dart';

String _type(List<String> keys) {
  var digits = '';
  for (final k in keys) {
    digits = AmountInput.press(
      digits,
      k == '<' ? const BackspaceKey() : DigitKey(k),
    );
  }
  return digits;
}

void main() {
  test('digits and 000 build the amount', () {
    expect(_type(['3', '5', '000']), '35000');
    expect(AmountInput.toAmount('35000'), 35000);
  });

  test('no leading zeros', () {
    expect(_type(['0', '000', '7']), '7');
  });

  test('backspace removes the last digit and is safe on empty', () {
    expect(_type(['1', '2', '<']), '1');
    expect(_type(['<']), '');
    expect(AmountInput.toAmount(''), 0);
  });

  test('stops at 12 digits', () {
    final full = _type(List.filled(12, '9'));
    expect(full.length, 12);
    expect(_type([...List.filled(12, '9'), '1']), full);
    expect(_type([...List.filled(11, '9'), '000']), '9' * 11);
  });
}
