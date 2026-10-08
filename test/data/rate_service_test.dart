import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/data/rates/rate_service.dart';
import 'package:personal_finance/data/rates/rate_source.dart';
import 'package:personal_finance/data/repositories/exchange_rate_repository.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';

import '../helpers/fake_rate_source.dart';
import '../helpers/test_db.dart';

class _Clock implements Clock {
  DateTime value = DateTime(2026, 10, 6, 9);
  @override
  DateTime now() => value;
}

void main() {
  group('CBU answer', () {
    test('is read into a day and a rate', () {
      final rate = CbuRateSource.parseCbu(
        '[{"id":1,"Code":"840","Ccy":"USD","Nominal":"1",'
        '"Rate":"11778.45","Diff":"5.5","Date":"06.10.2026"}]',
      );
      expect(rate.day, DateTime(2026, 10, 6));
      expect(rate.rate, 11778.45);
    });

    test('divides by the nominal', () {
      final rate = CbuRateSource.parseCbu(
        '[{"Nominal":"10","Rate":"126500","Date":"30.09.2026"}]',
      );
      expect(rate.rate, 12650);
    });

    test('anything else is refused', () {
      for (final body in ['', '[]', '{}', 'nope', '[{"Rate":"x"}]']) {
        expect(
          () => CbuRateSource.parseCbu(body),
          throwsA(isA<RateUnavailableException>()),
          reason: body,
        );
      }
    });
  });

  group('RateService', () {
    late AppDatabase db;
    late FakeRateSource source;
    late _Clock clock;
    late ExchangeRateRepository rates;
    late SettingsRepository settings;
    late RateService service;

    setUp(() {
      db = memoryDb();
      source = FakeRateSource();
      clock = _Clock();
      rates = ExchangeRateRepository(db);
      settings = SettingsRepository(db);
      service = RateService(source, rates, settings, clock);
    });
    tearDown(() => db.close());

    Future<double?> latest() async =>
        (await rates.watchLatest(Currency.usd).first)?.rate;

    test('refresh saves the rate and the time', () async {
      source.next = OfficialRate(day: DateTime(2026, 10, 6), rate: 11778.45);
      await service.refresh();
      expect(await latest(), 11778.45);
      expect((await settings.load()).usdRateFetchedAt, clock.value);
    });

    test('without internet the last rate stays', () async {
      source.next = OfficialRate(day: DateTime(2026, 10, 5), rate: 11770);
      await service.refresh();
      source.offline = true;
      clock.value = clock.value.add(const Duration(days: 1));
      await expectLater(
        service.refresh(),
        throwsA(isA<RateUnavailableException>()),
      );
      await service.refreshIfStale(); // Never throws.
      expect(await latest(), 11770);
    });

    test('refreshIfStale waits 3 hours between fetches', () async {
      await service.refreshIfStale();
      expect(source.calls, 1);
      clock.value = clock.value.add(const Duration(hours: 2));
      await service.refreshIfStale();
      expect(source.calls, 1);
      clock.value = clock.value.add(const Duration(hours: 2));
      await service.refreshIfStale();
      expect(source.calls, 2);
    });

    test('refreshIfStale does nothing with a manual rate', () async {
      await settings.setUsdRateManual(true);
      await service.refreshIfStale();
      expect(source.calls, 0);
    });
  });

  group('fillHistory', () {
    late AppDatabase db;
    late FakeRateSource source;
    late _Clock clock;
    late ExchangeRateRepository rates;
    late RateService service;

    setUp(() {
      db = memoryDb();
      source = FakeRateSource();
      clock = _Clock(); // 6 October 2026
      rates = ExchangeRateRepository(db);
      service = RateService(source, rates, SettingsRepository(db), clock);
    });
    tearDown(() => db.close());

    test('fetches the last day of each past month with no rate', () async {
      await rates.save(Currency.usd, DateTime(2026, 7, 10), 12480);
      await service.fillHistory();
      expect(source.days, [
        DateTime(2026, 5, 31),
        DateTime(2026, 6, 30),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 30),
      ]);
      final saved = await rates.getSince(Currency.usd, DateTime(2026));
      expect(saved, hasLength(5));

      // Nothing is missing now, so a second run fetches nothing.
      source.days.clear();
      await service.fillHistory();
      expect(source.days, isEmpty);
    });

    test('offline it stops quietly', () async {
      source.offline = true;
      await service.fillHistory();
      expect(await rates.getSince(Currency.usd, DateTime(2026)), isEmpty);
    });
  });

  test('UsdRate turns so\'m into cents', () {
    const rate = UsdRate(value: 12650, manual: false);
    expect(rate.toCents(1265000), 10000);
    expect(rate.toCents(35000), 277); // ≈ $2.77, like the design.
  });
}
