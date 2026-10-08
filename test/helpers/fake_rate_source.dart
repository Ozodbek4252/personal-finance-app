import 'package:personal_finance/data/rates/rate_source.dart';

/// A rate source that never uses the network.
class FakeRateSource implements RateSource {
  OfficialRate next = OfficialRate(day: DateTime(2026, 9, 30), rate: 12650);

  /// When true, every call fails like a phone without internet.
  bool offline = false;
  int calls = 0;

  /// The days asked for, in order. Null means "today".
  final days = <DateTime?>[];

  @override
  Future<OfficialRate> usd({DateTime? day}) async {
    calls++;
    if (offline) throw const RateUnavailableException('offline');
    days.add(day);
    // A past day gets the same rate, dated that day.
    return day == null ? next : OfficialRate(day: day, rate: next.rate);
  }
}
