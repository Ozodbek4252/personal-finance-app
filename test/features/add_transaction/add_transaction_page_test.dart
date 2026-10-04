import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/features/add_transaction/ui/add_transaction_page.dart';

import '../../helpers/test_db.dart';

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Add transaction'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, List<String> keys) async {
  for (final k in keys) {
    await tester.tap(find.bySemanticsLabel(k));
    await tester.pump();
  }
}

Future<List<TransactionRow>> _rows(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.transactions).get()))!;

void main() {
  testApp('adds an expense from the keypad', (tester, db) async {
    await _openAdd(tester);
    expect(find.byType(AddTransactionPage), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);

    await _type(tester, ['3', '5', '000']);
    expect(find.bySemanticsLabel('Amount 35 000 UZS'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Transportation'));
    await tester.pump();
    expect(find.text('Save expense · 35 000 UZS'), findsOneWidget);

    await tester.tap(find.text('Save expense · 35 000 UZS'));
    await tester.pumpAndSettle();

    expect(find.byType(AddTransactionPage), findsNothing);
    expect(find.text('Expense saved · 35 000 UZS'), findsOneWidget);
    final rows = await _rows(tester, db);
    expect(rows.single.amount, 35000);
    expect(rows.single.kind, TransactionKind.expense);
  });

  testApp('undo removes the saved transaction', (tester, db) async {
    await _openAdd(tester);
    await _type(tester, ['9']);
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    await tester.tap(find.textContaining('Save expense'));
    await tester.pumpAndSettle();
    expect(await _rows(tester, db), hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await _rows(tester, db), isEmpty);
  });

  testApp('adds income with a source', (tester, db) async {
    await _openAdd(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('SOURCE'), findsOneWidget);

    await _type(tester, ['1', '5', '000', '000']);
    await tester.tap(find.bySemanticsLabel('Salary'));
    await tester.pump();
    await tester.tap(find.text('Save income · +15 000 000'));
    await tester.pumpAndSettle();

    final row = (await _rows(tester, db)).single;
    expect(row.kind, TransactionKind.income);
    expect(row.amount, 15000000);
  });

  testApp('delete key and long press', (tester, db) async {
    await _openAdd(tester);
    await _type(tester, ['1', '2', '3']);
    await tester.tap(find.bySemanticsLabel('Delete digit'));
    await tester.pump();
    expect(find.bySemanticsLabel('Amount 12 UZS'), findsOneWidget);

    await tester.longPress(find.bySemanticsLabel('Delete digit'));
    await tester.pump();
    expect(find.bySemanticsLabel('Amount 0 UZS'), findsOneWidget);
  });

  testApp('note and payment method pickers', (tester, db) async {
    await _openAdd(tester);

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Korzinka');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Korzinka'), findsOneWidget);

    await tester.tap(find.text('Humo'));
    await tester.pumpAndSettle();
    expect(find.text('Payment method'), findsOneWidget);
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.text('Cash'), findsOneWidget);

    await _type(tester, ['5']);
    await tester.tap(find.bySemanticsLabel('Groceries'));
    await tester.pump();
    await tester.tap(find.textContaining('Save expense'));
    await tester.pumpAndSettle();

    final row = (await _rows(tester, db)).single;
    expect(row.note, 'Korzinka');
    final cash = (await tester.runAsync(
      () => (db.select(
        db.paymentMethods,
      )..where((m) => m.name.equals('Cash'))).getSingle(),
    ))!;
    expect(row.paymentMethodId, cash.id);
  });

  testApp('More shows every category', (tester, db) async {
    await _openAdd(tester);
    await tester.tap(find.bySemanticsLabel('More categories'));
    await tester.pumpAndSettle();
    expect(find.text('All categories'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Entertainment'),
      100,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Entertainment'));
    await tester.pumpAndSettle();
    // Picked from the full list, it now shows in the grid as selected.
    expect(find.bySemanticsLabel('Entertainment'), findsOneWidget);
  });
}
