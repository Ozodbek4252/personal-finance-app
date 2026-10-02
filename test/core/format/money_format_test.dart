import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/format/money_format.dart';

// Expected strings use " " (non-breaking space) and "−" (minus).
void main() {
  group('MoneyFormat.amount', () {
    test('groups thousands with a non-breaking space', () {
      expect(MoneyFormat.amount(12450000), '12 450 000');
      expect(MoneyFormat.amount(820000), '820 000');
      expect(MoneyFormat.amount(1000), '1 000');
      expect(MoneyFormat.amount(999), '999');
      expect(MoneyFormat.amount(0), '0');
    });

    test('uses a real minus sign', () {
      expect(MoneyFormat.amount(-35000), '−35 000');
    });
  });

  test('signed adds + for positive values only', () {
    expect(MoneyFormat.signed(15000000), '+15 000 000');
    expect(MoneyFormat.signed(-420000), '−420 000');
    expect(MoneyFormat.signed(0), '0');
  });

  test('withCurrency adds UZS', () {
    expect(MoneyFormat.withCurrency(820000), '820 000 UZS');
  });

  test('compact matches the chart labels', () {
    expect(MoneyFormat.compact(14500000, showSign: true), '+14.5M');
    expect(MoneyFormat.compact(-3900000), '−3.9M');
    expect(MoneyFormat.compact(15000000), '15M');
    expect(MoneyFormat.compact(850000), '850K');
    expect(MoneyFormat.compact(500), '500');
    // Same rounding as the design's chart labels.
    expect(MoneyFormat.compact(3050000), '3M');
    expect(MoneyFormat.compact(4650000), '4.7M');
    expect(MoneyFormat.compact(3480000), '3.5M');
  });

  test('parseDigits ignores spaces and other symbols', () {
    expect(MoneyFormat.parseDigits('35 000'), 35000);
    expect(MoneyFormat.parseDigits(''), 0);
  });

  group('PercentFormat', () {
    test('value', () {
      expect(PercentFormat.value(27), '27%');
      expect(PercentFormat.value(80.3), '80.3%');
      expect(PercentFormat.value(12, decimals: 1), '12.0%');
    });

    test('change', () {
      expect(PercentFormat.change(3.3), '+3.3%');
      expect(PercentFormat.change(-28.7), '−28.7%');
      expect(PercentFormat.change(0), '±0.0%');
    });

    test('points', () {
      expect(PercentFormat.points(8.9), '+8.9 pts');
      expect(PercentFormat.points(-1.6), '−1.6 pts');
    });
  });
}
