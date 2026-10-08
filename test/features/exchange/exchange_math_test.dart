import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/features/exchange/domain/exchange_math.dart';

void main() {
  test('buying gives so’m and gets dollars; selling is reversed', () {
    expect(
      ExchangeMath.currencyOf(ExchangeSide.give, selling: false),
      Currency.uzs,
    );
    expect(
      ExchangeMath.currencyOf(ExchangeSide.get, selling: false),
      Currency.usd,
    );
    expect(
      ExchangeMath.currencyOf(ExchangeSide.give, selling: true),
      Currency.usd,
    );
  });

  test('typed so’m become cents at the rate', () {
    expect(
      ExchangeMath.amounts(
        selling: false,
        typed: ExchangeSide.give,
        typedMinor: 1265000,
        rate: 12650,
      ),
      (give: 1265000, get: 10000),
    );
    // Rounds to the nearest cent: 1 000 000 / 12 650 = 79.0513…
    expect(
      ExchangeMath.amounts(
        selling: false,
        typed: ExchangeSide.give,
        typedMinor: 1000000,
        rate: 12650,
      ).get,
      7905,
    );
  });

  test('typed dollars become so’m at the rate', () {
    expect(
      ExchangeMath.amounts(
        selling: false,
        typed: ExchangeSide.get,
        typedMinor: 10000,
        rate: 11778.45,
      ),
      (give: 1177845, get: 10000),
    );
    expect(
      ExchangeMath.amounts(
        selling: true,
        typed: ExchangeSide.give,
        typedMinor: 4000,
        rate: 12600,
      ),
      (give: 4000, get: 504000),
    );
  });
}
