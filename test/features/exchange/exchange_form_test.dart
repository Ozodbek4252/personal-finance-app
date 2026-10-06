import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/features/add_transaction/ui/add_transaction_page.dart';
import 'package:personal_finance/router.dart';

import '../../helpers/test_db.dart';

Future<void> _open(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, List<String> keys) async {
  for (final k in keys) {
    final key = find.bySemanticsLabel(k);
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.textContaining(text);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<List<ExchangeRow>> _rows(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(
      () => (db.select(
        db.exchanges,
      )..orderBy([(e) => OrderingTerm.desc(e.id)])).get(),
    ))!;

Future<Map<int, int>> _balances(
  WidgetTester tester,
  AppDatabase db,
  Currency currency,
) async => (await tester.runAsync(
  () => TransactionRepository(
    db,
    const SystemClock(),
  ).getBalances(currency: currency),
))!;

void main() {
  testApp('the Exchange tab buys dollars at today’s rate', sampleData: true, (
    tester,
    db,
  ) async {
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exchange'));
    await tester.pumpAndSettle();
    expect(find.text('1 USD = 12 650 UZS'), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);

    final before = await _rows(tester, db);
    final usdBefore = await _balances(tester, db, Currency.usd);
    await _type(tester, ['1', '2', '6', '5', '000']);
    expect(find.text('1 265 000'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);

    await _tapText(tester, 'Convert 1\u00A0265\u00A0000\u00A0UZS → \$100');
    expect(find.byType(AddTransactionPage), findsNothing);
    expect(find.text('Exchange saved · 1 265 000 UZS → \$100'), findsOneWidget);

    final rows = await _rows(tester, db);
    expect(rows, hasLength(before.length + 1));
    final saved = rows.first;
    expect(
      (saved.fromAmount, saved.toAmount, saved.rate, saved.fee),
      (1265000, 10000, 12650, 0),
    );
    final usd = await _balances(tester, db, Currency.usd);
    expect(usd[saved.toMethodId], usdBefore[saved.toMethodId]! + 10000);
  });

  testApp('typing on “You get” works out the so’m', sampleData: true, (
    tester,
    db,
  ) async {
    await _open(tester, Routes.buyDollars);
    await tester.tap(find.bySemanticsLabel(RegExp('^You get, USD')));
    await tester.pump();
    await _type(tester, ['2', '0', '0']);
    expect(find.text(r'$200'), findsOneWidget);
    expect(find.text('2 530 000'), findsOneWidget);
  });

  testApp(
    'swap sells dollars, with a custom rate and a fee',
    sampleData: true,
    (tester, db) async {
      await _open(tester, Routes.buyDollars);
      await _type(tester, ['5', '0', '6', '000']);
      // The typed so'm move to "You get"; dollars are now given.
      await tester.tap(find.bySemanticsLabel('Swap direction'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^You give, USD')), findsOneWidget);
      expect(find.text('506 000'), findsOneWidget);
      expect(find.text(r'$40.00'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Edit rate'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12600');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Your rate for this exchange.'), findsOneWidget);
      expect(find.text(r'$40.16'), findsOneWidget);

      await _tapText(tester, 'Add fee');
      await tester.enterText(find.byType(TextField), '1.5');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text(r'Fee $1.50'), findsOneWidget);

      await _tapText(tester, 'Convert');
      final saved = (await _rows(tester, db)).first;
      expect(
        (saved.fromAmount, saved.toAmount, saved.rate, saved.fee),
        (4016, 506000, 12600, 150),
      );
    },
  );

  testApp('Sell USD opens in sell mode', sampleData: true, (tester, db) async {
    await _open(tester, Routes.sellDollars);
    expect(find.bySemanticsLabel(RegExp('^You give, USD')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^You get, UZS')), findsOneWidget);
  });

  testApp('without a rate it asks for one', (tester, db) async {
    await _open(tester, Routes.buyDollars);
    await _type(tester, ['5']);
    expect(find.text('Add a rate first'), findsOneWidget);
    expect(find.textContaining('No rate yet'), findsOneWidget);
  });

  testApp('switching back to Expense keeps the expense form', (
    tester,
    db,
  ) async {
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await _type(tester, ['7']);
    await tester.tap(find.text('Exchange'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Amount 7\sUZS')), findsOneWidget);
  });
}
