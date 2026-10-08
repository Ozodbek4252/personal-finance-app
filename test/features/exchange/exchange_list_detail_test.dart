import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/features/exchange/ui/edit_exchange_page.dart';
import 'package:personal_finance/features/exchange/ui/exchange_detail_page.dart';

import '../../helpers/test_db.dart';

Future<void> _openTab(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Transactions'));
  await tester.pumpAndSettle();
}

/// Lets database work and streams finish, then rebuilds.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<List<ExchangeRow>> _rows(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(
      () => (db.select(
        db.exchanges,
      )..orderBy([(e) => OrderingTerm.asc(e.id)])).get(),
    ))!;

/// Taps the 30 Sep exchange row (+$100.00).
Future<void> _openTodayExchange(WidgetTester tester) async {
  final row = find.text(r'+$100.00');
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(ExchangeDetailPage), findsOneWidget);
}

void main() {
  testApp('exchange rows show what came in and went out', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    expect(find.text(r'+$100.00'), findsOneWidget);
    expect(find.text('−1 265 000 UZS'), findsOneWidget);
    expect(find.text('UZS → USD · 11:30'), findsOneWidget);
    // The day total ignores the exchange, like the design.
    expect(find.text('+14 545 000'), findsOneWidget);
  });

  testApp('the Exchanges chip shows only exchanges', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.ensureVisible(find.text('Exchanges'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exchanges'));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
    expect(find.text('Exchange'), findsNWidgets(2));
    expect(find.text('Groceries'), findsNothing);
  });

  testApp('“Show USD in transaction list” adds ≈ \$', sampleData: true, (
    tester,
    db,
  ) async {
    await tester.runAsync(() => SettingsRepository(db).setShowUsdInList(true));
    await _settle(tester);
    await _openTab(tester);
    // 420 000 UZS at 12 650 ≈ $33.
    expect(find.text('≈ \$33 · Uzcard'), findsOneWidget);
  });

  testApp('details show the exchange; delete can be undone', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await _openTodayExchange(tester);
    expect(find.text('Humo'), findsOneWidget);
    expect(find.text('Cash (USD)'), findsOneWidget);
    expect(find.text('1 USD = 12 650 UZS'), findsOneWidget);
    final before = await _rows(tester, db);

    await tester.tap(find.bySemanticsLabel('Delete exchange').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete this exchange?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await _settle(tester);
    expect(find.byType(ExchangeDetailPage), findsNothing);
    expect(await _rows(tester, db), hasLength(before.length - 1));

    await tester.tap(find.text('Undo'));
    await _settle(tester);
    expect(await _rows(tester, db), before);
  });

  testApp('Edit changes the rate and keeps the rest', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await _openTodayExchange(tester);
    final before = (await _rows(tester, db)).last;

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(EditExchangePage), findsOneWidget);
    expect(find.text('1 265 000'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
    // Balance shows the change once, not twice: $300 before this one.
    expect(find.text(r'Balance $200.00 → $300.00'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Edit rate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12500');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final save = find.text('Save changes');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await _settle(tester);

    expect(find.byType(EditExchangePage), findsNothing);
    final after = (await _rows(tester, db)).last;
    expect(after.id, before.id);
    expect(
      (after.fromAmount, after.toAmount, after.rate),
      (1265000, 10120, 12500),
    );
    expect(after.occurredAt, before.occurredAt);
    expect(find.text(r'+$101.20'), findsOneWidget);
  });
}
