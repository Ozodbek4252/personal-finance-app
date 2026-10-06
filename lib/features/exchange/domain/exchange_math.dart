import '../../../data/models/currency.dart';

/// The two cards on the Exchange screen.
enum ExchangeSide { give, get }

/// Money on both sides of an exchange, in the smallest unit of each
/// side's currency (so'm or cents).
typedef ExchangeAmounts = ({int give, int get});

/// Rules for turning what the user typed into both amounts.
abstract final class ExchangeMath {
  /// The currency on [side]. Buying dollars gives so'm and gets
  /// dollars; selling is the other way round.
  static Currency currencyOf(ExchangeSide side, {required bool selling}) {
    final givesSom = !selling;
    final isGive = side == ExchangeSide.give;
    return isGive == givesSom ? Currency.uzs : Currency.usd;
  }

  /// [whole] is what was typed on the [typed] card, in whole so'm or
  /// whole dollars. The other card is worked out with [rate] (UZS for
  /// 1 USD) and rounded to the nearest so'm or cent.
  static ExchangeAmounts amounts({
    required bool selling,
    required ExchangeSide typed,
    required int whole,
    required double rate,
  }) {
    final typedCurrency = currencyOf(typed, selling: selling);
    final typedMinor = whole * typedCurrency.minorUnits;
    final otherMinor = typedCurrency == Currency.uzs
        ? (typedMinor * 100 / rate).round()
        : (typedMinor * rate / 100).round();
    return typed == ExchangeSide.give
        ? (give: typedMinor, get: otherMinor)
        : (give: otherMinor, get: typedMinor);
  }
}
