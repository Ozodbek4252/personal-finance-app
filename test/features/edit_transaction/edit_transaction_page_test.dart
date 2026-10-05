import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/features/edit_transaction/ui/edit_transaction_page.dart';

import '../../helpers/fake_receipts.dart';
import '../../helpers/test_db.dart';

/// Opens the "Korzinka" transaction, then its edit form.
Future<void> _openEdit(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Transactions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Korzinka · 13:40'));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('Edit transaction'));
  await tester.pumpAndSettle();
}

Future<TransactionRow> _korzinka(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((t) => t.note.equals('Korzinka'))).getSingle(),
    ))!;

/// Taps a widget that may be below the fold of the form.
Future<void> _tapInForm(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testApp('form starts with the saved values', sampleData: true, (
    tester,
    db,
  ) async {
    await _openEdit(tester);
    expect(find.byType(EditTransactionPage), findsOneWidget);
    expect(find.text('420 000'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Wed, 30 Sep 2026 · 13:40'), findsOneWidget);
    expect(find.text('Uzcard'), findsOneWidget);
    expect(find.text('Korzinka'), findsOneWidget);
    expect(find.text('Created 30 Sep, 13:41'), findsOneWidget);
  });

  testApp('saves a new amount and note', sampleData: true, (tester, db) async {
    await _openEdit(tester);
    await tester.enterText(find.byType(TextField).first, '400000');
    await tester.enterText(find.widgetWithText(TextField, 'Korzinka'), 'Havas');
    await tester.pump();
    expect(find.text('400 000'), findsOneWidget);

    await _tapInForm(tester, find.text('Save changes'));

    expect(find.byType(EditTransactionPage), findsNothing);
    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('−400 000'), findsOneWidget);
    expect(find.text('Havas'), findsOneWidget);
  });

  testApp('switching to income asks for a source', sampleData: true, (
    tester,
    db,
  ) async {
    await _openEdit(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Choose'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Source: Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary'));
    await tester.pumpAndSettle();
    await _tapInForm(tester, find.text('Save changes'));

    final row = await _korzinka(tester, db);
    expect(row.kind, TransactionKind.income);
    expect(find.text('+420 000'), findsOneWidget);
  });

  testApp('cancel asks before losing changes', sampleData: true, (
    tester,
    db,
  ) async {
    await _openEdit(tester);
    // No changes: Cancel just closes.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(EditTransactionPage), findsNothing);

    await tester.tap(find.bySemanticsLabel('Edit transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(EditTransactionPage), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(EditTransactionPage), findsNothing);
    expect((await _korzinka(tester, db)).amount, 420000);
  });

  final store = FakeReceiptStore();
  testApp(
    'adds a receipt photo',
    sampleData: true,
    overrides: fakeReceiptOverrides(store),
    (tester, db) async {
      await _openEdit(tester);
      await _tapInForm(tester, find.text('Add photo'));
      await tester.tap(find.text('Choose from library'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt photo'), findsOneWidget);

      await _tapInForm(tester, find.text('Save changes'));
      expect((await _korzinka(tester, db)).receiptPath, store.saved.single);
      expect(find.text('RECEIPT'), findsOneWidget);
    },
  );

  final addStore = FakeReceiptStore();
  testApp(
    'add expense can attach a receipt',
    overrides: fakeReceiptOverrides(addStore),
    (tester, db) async {
      await tester.tap(find.bySemanticsLabel('Add transaction'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Attach receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Receipt attached'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('5'));
      await tester.tap(find.bySemanticsLabel('Food'));
      await tester.pump();
      await tester.tap(find.textContaining('Save expense'));
      await tester.pumpAndSettle();

      final row = (await tester.runAsync(
        () => db.select(db.transactions).getSingle(),
      ))!;
      expect(row.receiptPath, addStore.saved.single);
      expect(addStore.deleted, isEmpty, reason: 'saved photo is kept');
    },
  );
}
