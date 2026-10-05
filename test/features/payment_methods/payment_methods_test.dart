import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/features/payment_methods/ui/payment_methods_page.dart';
import 'package:personal_finance/router.dart';

import '../../helpers/test_db.dart';

Future<void> _open(WidgetTester tester) async {
  GoRouter.of(
    tester.element(find.byType(Scaffold).first),
  ).push(Routes.paymentMethods);
  await tester.pumpAndSettle();
}

Future<PaymentMethodRow> _method(
  WidgetTester tester,
  AppDatabase db,
  String name,
) async => (await tester.runAsync(
  () => (db.select(
    db.paymentMethods,
  )..where((m) => m.name.equals(name))).getSingle(),
))!;

void main() {
  testApp('shows the default and the list with badges', sampleData: true, (
    tester,
    db,
  ) async {
    await _open(tester);
    expect(find.byType(PaymentMethodsPage), findsOneWidget);
    expect(find.text('Default for new transactions'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.textContaining('transactions this month'), findsWidgets);
  });

  testApp('adds a custom method and blocks duplicates', (tester, db) async {
    await _open(tester);
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'humo');
    await tester.pump();
    expect(find.text('You already have this method'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Payme');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final payme = await _method(tester, db, 'Payme');
    expect(payme.isCustom, isTrue);
  });

  testApp('changes the default method', (tester, db) async {
    await _open(tester);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();

    final cash = await _method(tester, db, 'Cash');
    final settings = await tester.runAsync(() => SettingsRepository(db).load());
    expect(settings!.defaultPaymentMethodId, cash.id);
  });

  testApp('rename, starting balance and remove', (tester, db) async {
    await _open(tester);

    await tester.tap(find.text('Visa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Visa Gold');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await _method(tester, db, 'Visa Gold')).isCustom, isFalse);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starting balance'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '2000000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await _method(tester, db, 'Cash')).openingBalance, 2000000);

    await tester.tap(find.text('Mastercard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect((await _method(tester, db, 'Mastercard')).isArchived, isTrue);
    expect(find.text('Mastercard'), findsNothing);
  });

  testApp('the default method cannot be removed', (tester, db) async {
    await _open(tester);
    await tester.tap(find.text('Humo').last);
    await tester.pumpAndSettle();
    expect(find.text('Make default'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testApp('the add screen links to payment methods', (tester, db) async {
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Humo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage payment methods'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentMethodsPage), findsOneWidget);
  });
}
