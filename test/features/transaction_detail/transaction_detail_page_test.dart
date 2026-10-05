import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/features/transaction_detail/ui/transaction_detail_page.dart';

import '../../helpers/test_db.dart';

/// Opens the details of the "Korzinka" groceries transaction.
Future<void> _openKorzinka(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Transactions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Korzinka · 13:40'));
  await tester.pumpAndSettle();
}

Future<int> _count(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.transactions.count().getSingle()))!;

void main() {
  testApp('shows every detail like the design', sampleData: true, (
    tester,
    db,
  ) async {
    await _openKorzinka(tester);
    expect(find.byType(TransactionDetailPage), findsOneWidget);
    expect(find.text('−420 000'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Wed, 30 Sep 2026 · 13:40'), findsOneWidget);
    expect(find.text('Uzcard'), findsOneWidget);
    expect(find.text('Korzinka'), findsOneWidget);
    expect(
      find.text('Weekly groceries, cleaning supplies and bread'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Groceries in September: 820 000 UZS across 6 '
        'transactions — 27% of your spending.',
      ),
      findsOneWidget,
    );
  });

  testApp('cancel keeps the transaction', sampleData: true, (tester, db) async {
    final before = await _count(tester, db);
    await _openKorzinka(tester);
    await tester.tap(find.bySemanticsLabel('Delete transaction').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete this transaction?'), findsOneWidget);
    expect(find.text('Korzinka · Today, 13:40'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailPage), findsOneWidget);
    expect(await _count(tester, db), before);
  });

  testApp('delete removes it, undo brings it back', sampleData: true, (
    tester,
    db,
  ) async {
    final before = await _count(tester, db);
    await _openKorzinka(tester);
    await tester.tap(find.bySemanticsLabel('Delete transaction').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailPage), findsNothing);
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Korzinka · 13:40'), findsNothing);
    expect(await _count(tester, db), before - 1);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await _count(tester, db), before);
    expect(find.text('Korzinka · 13:40'), findsOneWidget);
  });

  testApp('duplicate adds a copy for today', sampleData: true, (
    tester,
    db,
  ) async {
    final before = await _count(tester, db);
    await _openKorzinka(tester);
    await tester.scrollUntilVisible(find.text('Duplicate'), 200);
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Copy added with today’s date'), findsOneWidget);
    expect(await _count(tester, db), before + 1);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // The copy is dated "now" (the demo clock starts at 30 Sep, 15:00).
    expect(find.textContaining('Wed, 30 Sep 2026 · 15:0'), findsOneWidget);
  });

  testApp('unknown id shows a message', (tester, db) async {
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).push('/transaction/9999');
    await tester.pumpAndSettle();
    expect(find.text('This transaction no longer exists.'), findsOneWidget);
  });
}
