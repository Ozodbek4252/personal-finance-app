import '../../core/time/clock.dart';
import '../models/currency.dart';
import '../repositories/exchange_rate_repository.dart';
import '../repositories/settings_repository.dart';
import 'rate_source.dart';

/// The USD rate the app uses right now.
class UsdRate {
  const UsdRate({required this.value, required this.manual, this.updatedAt});

  /// UZS for 1 USD.
  final double value;

  /// True when the user typed it (Settings > Currencies > Manual).
  final bool manual;

  /// When the CBU rate was fetched. Null for a manual rate.
  final DateTime? updatedAt;

  /// Turns so'm into cents at this rate.
  int toCents(int som) => (som * 100 / value).round();
}

/// Gets today's CBU rate and saves it. Without internet, the last saved
/// rate stays in use.
class RateService {
  RateService(this._source, this._rates, this._settings, this._clock);

  final RateSource _source;
  final ExchangeRateRepository _rates;
  final SettingsRepository _settings;
  final Clock _clock;

  /// A fetched rate is fresh for this long. CBU sets one rate a day.
  static const maxAge = Duration(hours: 3);

  /// Fetches and saves today's rate. Throws [RateUnavailableException]
  /// when it cannot; the saved rates do not change then.
  Future<OfficialRate> refresh() async {
    final rate = await _source.usd();
    await _rates.save(Currency.usd, rate.day, rate.rate);
    await _settings.setUsdRateFetchedAt(_clock.now());
    return rate;
  }

  /// Fetches the rate when it is older than [maxAge] and the user did
  /// not switch to a manual rate. Never throws: this runs in the
  /// background when the app opens.
  Future<void> refreshIfStale() async {
    try {
      final settings = await _settings.load();
      if (settings.usdRateManual) return;
      final fetched = settings.usdRateFetchedAt;
      if (fetched != null && _clock.now().difference(fetched) < maxAge) {
        return;
      }
      await refresh();
    } on Object {
      // No internet or a server problem. The last saved rate is used.
    }
  }
}
