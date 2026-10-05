import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/format/amount_input_formatter.dart';

String _format(String typed, {String old = ''}) => const AmountInputFormatter()
    .formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(text: typed),
    )
    .text;

void main() {
  test('groups digits and drops other characters', () {
    expect(_format('420000'), '420 000');
    expect(_format('4a2-0'), '420');
  });

  test('drops leading zeros and allows empty', () {
    expect(_format('0005'), '5');
    expect(_format(''), '');
  });

  test('keeps the old text when too long', () {
    expect(_format('1' * 13, old: '1'), '1');
  });
}
