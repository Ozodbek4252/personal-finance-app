import '../../../data/models/currency.dart';
import '../../../data/models/exchange_details.dart';

/// What the user's dollars cost and what they are worth now.
///
/// Uses the average cost: buying adds dollars and the so'm paid for
/// them; selling removes dollars and the same share of the so'm paid.
/// Dollars from a starting balance have no known price, so they are
/// left out of [boughtCents] and [paid].
class DollarStats {
  const DollarStats({
    required this.cents,
    required this.boughtCents,
    required this.paid,
  });

  /// Dollars held now on all dollar methods, in cents.
  final int cents;

  /// The part of [cents] that was bought in tracked exchanges.
  final int boughtCents;

  /// So'm paid for [boughtCents] (fees not included).
  final int paid;

  static const empty = DollarStats(cents: 0, boughtCents: 0, paid: 0);

  /// UZS paid for 1 USD on average, or null with no tracked dollars.
  double? get averageRate => boughtCents == 0 ? null : paid * 100 / boughtCents;

  /// So'm the tracked dollars are worth at [rate] minus what was paid:
  /// positive when the dollar went up.
  int? valueChange(double rate) =>
      boughtCents == 0 ? null : (boughtCents * rate / 100).round() - paid;

  /// [exchanges] in any order; [cents] from the dollar balances.
  static DollarStats build({
    required List<ExchangeDetails> exchanges,
    required int cents,
  }) {
    final oldestFirst = [...exchanges]
      ..sort((a, b) {
        final byTime = a.occurredAt.compareTo(b.occurredAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    var bought = 0;
    var paid = 0;
    for (final e in oldestFirst) {
      final x = e.exchange;
      if (e.fromCurrency == Currency.uzs && e.toCurrency == Currency.usd) {
        bought += x.toAmount;
        paid += x.fromAmount;
      } else if (e.fromCurrency == Currency.usd && bought > 0) {
        final sold = (x.fromAmount + x.fee).clamp(0, bought);
        paid -= (paid * sold / bought).round();
        bought -= sold;
      }
    }
    // Never count more dollars as bought than the user holds now (for
    // example after spending dollars outside the app).
    if (bought > cents && bought > 0) {
      paid = (paid * cents.clamp(0, bought) / bought).round();
      bought = cents.clamp(0, bought);
    }
    return DollarStats(cents: cents, boughtCents: bought, paid: paid);
  }
}
