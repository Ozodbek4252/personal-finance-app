import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/providers/data_providers.dart';
import 'package:personal_finance/features/add_transaction/ui/add_transaction_page.dart';
import 'package:personal_finance/features/dollars/ui/dollar_balance_page.dart';
import 'package:personal_finance/features/transactions/ui/transactions_page.dart';

import '../../helpers/fake_rate_source.dart';
import '../../helpers/test_db.dart';

/// Lets database work and streams finish, then rebuilds.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp(r'^Dollar balance')));
  await _settle(tester);
  expect(find.byType(DollarBalancePage), findsOneWidget);
}

/// Scrolls the page until [finder] is built and on screen.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await _scrollTo(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  final source = FakeRateSource();
  setUp(() {
    source
      ..offline = false
      ..days.clear();
  });

  testApp(
    'Home’s dollar row opens the page with the design’s numbers',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      expect(find.text(r'$500.00'), findsOneWidget);
      expect(find.text('12 542'), findsOneWidget);
      expect(find.text('6 271 000 UZS'), findsOneWidget);
      expect(find.text('+54 000 UZS'), findsOneWidget);
      expect(find.text('+0.7% this month · +1.9% since April'), findsOneWidget);
      await _scrollTo(tester, find.text('Visa USD card'));
      await _scrollTo(tester, find.text('30 Sep · rate 12 650'));
      // Sample data has every month, so nothing is fetched.
      expect(source.days, isEmpty);
    },
  );

  testApp(
    '“All” shows every exchange on the Transactions tab',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      await _tapText(tester, 'All');
      expect(find.byType(DollarBalancePage), findsNothing);
      expect(find.byType(TransactionsPage), findsOneWidget);
      expect(find.text('3 results'), findsOneWidget);
    },
  );

  testApp(
    'Buy and Sell open the Exchange tab',
    sampleData: true,
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      await _tapText(tester, 'Sell USD');
      expect(find.byType(AddTransactionPage), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^You give, USD')), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();

      await _tapText(tester, 'Buy USD');
      expect(find.bySemanticsLabel(RegExp('^You give, UZS')), findsOneWidget);
    },
  );

  testApp(
    'with no dollars it shows dashes and fills the rate history',
    overrides: [rateSourceProvider.overrideWithValue(source)],
    (tester, db) async {
      await _open(tester);
      expect(find.text(r'$0.00'), findsWidgets);
      expect(find.text('—'), findsWidgets);
      await _scrollTo(tester, find.textContaining('No exchanges yet'));
      // Opening the page fetched the five past months.
      expect(source.days, hasLength(5));
    },
  );
}
