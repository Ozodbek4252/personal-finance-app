import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/providers/data_providers.dart';
import 'package:personal_finance/data/rates/rate_source.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/features/currencies/ui/currencies_page.dart';

import '../../helpers/fake_rate_source.dart';
import '../../helpers/test_db.dart';

/// Opens Settings > Currencies.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Primary currency'));
  await tester.pumpAndSettle();
  expect(find.byType(CurrenciesPage), findsOneWidget);
}

Future<AppSettings> _saved(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => SettingsRepository(db).load()))!;

/// Lets database work and streams finish, then rebuilds.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  final source = FakeRateSource();
  setUp(() {
    source
      ..offline = false
      ..calls = 0
      ..next = OfficialRate(day: DateTime(2026, 9, 30), rate: 12650);
  });

  testApp(
    'shows both currencies and the saved CBU rate',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('1 USD = 12 650 UZS'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(source.calls, 0, reason: 'opening the page does not fetch');
    },
  );

  testApp(
    'Refresh gets a new rate; offline shows a message',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      source.next = OfficialRate(day: DateTime(2026, 9, 30), rate: 11778.45);
      await tester.tap(find.text('Refresh'));
      await _settle(tester);
      expect(find.text('1 USD = 11 778.45 UZS'), findsOneWidget);
      expect(find.text('Updated today, 15:00'), findsOneWidget);

      source.offline = true;
      await tester.tap(find.text('Refresh'));
      await _settle(tester);
      expect(find.textContaining('Could not get the rate'), findsOneWidget);
      expect(find.text('1 USD = 11 778.45 UZS'), findsOneWidget);
    },
  );

  testApp(
    'display switches are saved',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      var saved = await _saved(tester, db);
      expect(
        (saved.showUsdOnHome, saved.showUsdInList, saved.roundDollars),
        (true, false, true),
      );

      await tester.tap(find.text('Show USD on home'));
      await tester.tap(find.text('Show USD in transaction list'));
      await tester.tap(find.text('Round dollars'));
      await _settle(tester);
      saved = await _saved(tester, db);
      expect(
        (saved.showUsdOnHome, saved.showUsdInList, saved.roundDollars),
        (false, true, false),
      );
    },
  );

  testApp(
    'Manual starts from the CBU rate and can be edited',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      await tester.tap(find.text('Manual'));
      await _settle(tester);
      expect(find.text('Your own rate'), findsOneWidget);
      expect(find.text('1 USD = 12 650 UZS'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12700,5');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await _settle(tester);
      expect(find.text('1 USD = 12 700.50 UZS'), findsOneWidget);
      final saved = await _saved(tester, db);
      expect(saved.usdRateManual, isTrue);
      expect(saved.usdManualRate, 12700.5);

      // Back to Auto uses the saved CBU rate again.
      await tester.tap(find.text('Auto (CBU)'));
      await _settle(tester);
      expect(find.text('1 USD = 12 650 UZS'), findsOneWidget);
    },
  );

  testApp(
    'with no rate at all it says so',
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      expect(find.text('1 USD = — UZS'), findsOneWidget);
      expect(find.textContaining('No rate yet'), findsOneWidget);
    },
  );
}
