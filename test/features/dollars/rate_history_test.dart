import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/features/dollars/domain/rate_history.dart';

ExchangeRateRow _r(int month, int day, double rate) => ExchangeRateRow(
  currency: Currency.usd,
  day: DateTime(2026, month, day),
  rate: rate,
);

void main() {
  test('one point per month: the last rate in it', () {
    final points = RateHistory.monthly([
      _r(8, 15, 12560),
      _r(9, 1, 12600),
      _r(9, 30, 12650),
    ]);
    expect(points, [
      (month: DateTime(2026, 8), rate: 12560.0),
      (month: DateTime(2026, 9), rate: 12650.0),
    ]);
  });

  test('grid lines are round and few, like the design', () {
    expect(RateHistory.ticks([12410, 12470, 12520, 12480, 12560, 12650]), [
      12400,
      12500,
      12600,
      12700,
    ]);
    final flat = RateHistory.ticks([11778.45, 11778.45]);
    expect(flat.length, inInclusiveRange(3, 5));
    expect(flat.first, lessThan(11778.45));
    expect(flat.last, greaterThan(11778.45));
    expect(RateHistory.ticks(const []), isEmpty);
  });

  test('change in percent', () {
    expect(RateHistory.change(12560, 12650), closeTo(0.72, 0.01));
    expect(RateHistory.change(12410, 12650), closeTo(1.93, 0.01));
  });
}
