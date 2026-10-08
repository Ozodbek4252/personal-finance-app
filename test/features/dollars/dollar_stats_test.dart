import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/data/models/exchange_details.dart';
import 'package:personal_finance/features/dollars/domain/dollar_stats.dart';
import 'package:personal_finance/features/dollars/domain/rate_insight.dart';

PaymentMethodRow _method(int id, Currency currency) => PaymentMethodRow(
  id: id,
  name: currency == Currency.uzs ? 'Humo' : 'Cash (USD)',
  iconKey: 'card',
  isCustom: false,
  sortOrder: id,
  openingBalance: 0,
  isArchived: false,
  currency: currency,
);

final _humo = _method(1, Currency.uzs);
final _cash = _method(2, Currency.usd);
var _nextId = 1;

/// Buying [dollars] at [rate] on [day] of September.
ExchangeDetails _buy(int day, int dollars, double rate) =>
    _exchange(day, _humo, (dollars * rate).round(), _cash, dollars * 100, rate);

ExchangeDetails _sell(int day, int dollars, double rate, {int fee = 0}) =>
    _exchange(
      day,
      _cash,
      dollars * 100,
      _humo,
      (dollars * rate).round(),
      rate,
      fee: fee,
    );

ExchangeDetails _exchange(
  int day,
  PaymentMethodRow from,
  int fromAmount,
  PaymentMethodRow to,
  int toAmount,
  double rate, {
  int fee = 0,
}) {
  final at = DateTime(2026, 9, day);
  return ExchangeDetails(
    exchange: ExchangeRow(
      id: _nextId++,
      fromMethodId: from.id,
      fromAmount: fromAmount,
      toMethodId: to.id,
      toAmount: toAmount,
      rate: rate,
      fee: fee,
      occurredAt: at,
      createdAt: at,
      updatedAt: at,
    ),
    from: from,
    to: to,
  );
}

void main() {
  test('the design’s three buys: average 12 542, value +54 000', () {
    final stats = DollarStats.build(
      exchanges: [
        _buy(30, 100, 12650),
        _buy(1, 200, 12470),
        _buy(12, 200, 12560),
      ],
      cents: 50000,
    );
    expect(stats.paid, 6271000);
    expect(stats.averageRate!.round(), 12542);
    expect(stats.valueChange(12650), 54000);
  });

  test('selling removes the same share of what was paid', () {
    final stats = DollarStats.build(
      exchanges: [
        _buy(1, 100, 12000),
        _buy(2, 100, 13000),
        _sell(3, 50, 12800),
      ],
      cents: 15000,
    );
    expect(stats.boughtCents, 15000);
    expect(stats.averageRate, 12500);
    expect(stats.paid, 1875000);
  });

  test('dollars from a starting balance have no price', () {
    final none = DollarStats.build(exchanges: const [], cents: 30000);
    expect(none.averageRate, isNull);
    expect(none.valueChange(12650), isNull);

    final some = DollarStats.build(
      exchanges: [_buy(1, 100, 12000)],
      cents: 40000,
    );
    expect(some.boughtCents, 10000);
    expect(some.paid, 1200000);
  });

  test('dollars spent outside the app shrink the tracked part', () {
    final stats = DollarStats.build(
      exchanges: [_buy(1, 100, 12000)],
      cents: 2500,
    );
    expect(stats.boughtCents, 2500);
    expect(stats.paid, 300000);
  });

  group('rate insight', () {
    final stats = DollarStats.build(
      exchanges: [
        _buy(1, 200, 12470),
        _buy(12, 200, 12560),
        _buy(30, 100, 12650),
      ],
      cents: 50000,
    );

    test('matches the design when the rate rose', () {
      final insight = dollarRateInsight(
        monthStartRate: 12560,
        rate: 12650,
        stats: stats,
      );
      expect(
        insight?.plainText,
        'The dollar rate rose 0.7% this month. Your \$500 is now worth '
        '54 000 UZS more than you paid.',
      );
    });

    test('says “fell” and “less” when the rate went down', () {
      final insight = dollarRateInsight(
        monthStartRate: 12650,
        rate: 12400,
        stats: stats,
      );
      expect(insight?.plainText, startsWith('The dollar rate fell 2.0%'));
      expect(insight?.plainText, contains('less than you paid'));
    });

    test('only the rate sentence without tracked dollars', () {
      final insight = dollarRateInsight(
        monthStartRate: 12560,
        rate: 12650,
        stats: DollarStats.empty,
      );
      expect(insight?.plainText, 'The dollar rate rose 0.7% this month.');
    });

    test('nothing when a rate is missing or did not move', () {
      expect(
        dollarRateInsight(monthStartRate: null, rate: 12650, stats: stats),
        isNull,
      );
      expect(
        dollarRateInsight(monthStartRate: 12650, rate: 12651, stats: stats),
        isNull,
      );
    });
  });
}
