import '../../../data/db/app_database.dart';

/// The rate of one month: the last saved rate in it.
typedef MonthRate = ({DateTime month, double rate});

abstract final class RateHistory {
  /// One point per calendar month, oldest first. [rows] must be sorted
  /// by day, oldest first.
  static List<MonthRate> monthly(List<ExchangeRateRow> rows) {
    final points = <MonthRate>[];
    for (final r in rows) {
      final month = DateTime(r.day.year, r.day.month);
      if (points.isNotEmpty && points.last.month == month) {
        points[points.length - 1] = (month: month, rate: r.rate);
      } else {
        points.add((month: month, rate: r.rate));
      }
    }
    return points;
  }

  /// Change in percent from [from] to [to].
  static double change(double from, double to) => (to - from) / from * 100;

  /// Round grid lines around [values], 3 to 5 of them:
  /// 12 410 … 12 650 → 12 400, 12 500, 12 600, 12 700.
  static List<double> ticks(Iterable<double> values) {
    if (values.isEmpty) return const [];
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    const steps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000];
    for (final step in steps) {
      var from = (low / step).floor() * step;
      var to = (high / step).ceil() * step;
      if ((to - from) / step <= 4) {
        // A flat line still gets room above and below.
        if ((to - from) / step < 2) {
          from -= step;
          to += step;
        }
        return [for (var t = from; t <= to; t += step) t.toDouble()];
      }
    }
    // Very wide ranges: just the two ends.
    low = low.floorToDouble();
    high = high.ceilToDouble();
    return [low, high];
  }
}
