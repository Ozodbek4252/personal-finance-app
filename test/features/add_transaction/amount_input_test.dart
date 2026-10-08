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

  group('with cents', () {
    String type(String keys) {
      var text = '';
      for (final k in keys.split(' ')) {
        text = AmountInput.pressDecimal(text, switch (k) {
          '<' => const BackspaceKey(),
          '.' => const DecimalKey(),
          _ => DigitKey(k),
        });
      }
      return text;
    }

    test('one dot and at most two digits after it', () {
      expect(type('1 0 0 . 5 0'), '100.50');
      expect(type('1 . 2 3 4'), '1.23');
      expect(type('1 . . 2'), '1.2');
      expect(type('. 5'), '0.5');
      expect(type('0 0 7'), '7');
      expect(type('1 . 5 <'), '1.');
      expect(type('1 . 5 < <'), '1');
    });

    test('so’m ignore the dot', () {
      expect(AmountInput.press('12', const DecimalKey()), '12');
    });

    test('text ↔ cents', () {
      expect(AmountInput.toCents(''), 0);
      expect(AmountInput.toCents('100'), 10000);
      expect(AmountInput.toCents('100.'), 10000);
      expect(AmountInput.toCents('100.5'), 10050);
      expect(AmountInput.toCents('0.07'), 7);
      expect(AmountInput.fromCents(10050), '100.5');
      expect(AmountInput.fromCents(10007), '100.07');
      expect(AmountInput.fromCents(10000), '100');
      expect(AmountInput.fromCents(0), '');
    });
  });
}
