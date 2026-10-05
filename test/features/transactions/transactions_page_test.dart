import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

// Amount texts use "−" (minus) and " " (non-breaking space).

Future<void> _openTab(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Transactions'));
  await tester.pumpAndSettle();
}

void main() {
  testApp('shows totals and the day groups', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    expect(find.text('+15 500 000'), findsOneWidget);
    expect(find.text('−3 050 000'), findsOneWidget);
    expect(find.text('+12 450 000'), findsOneWidget);
    expect(find.text('41 transactions'), findsOneWidget);
    expect(find.text('TODAY · 30 SEP'), findsOneWidget);
    expect(find.text('+14 545 000'), findsOneWidget);
    expect(find.text('Korzinka · 13:40'), findsOneWidget);
  });

  testApp('search shows results and can be cleared', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.enterText(find.byType(TextField), 'taxi');
    await tester.pumpAndSettle();

    // Search switches to results mode: flat list with dates.
    expect(find.text('4 results for “taxi”'), findsOneWidget);
    expect(find.text('−148 000'), findsOneWidget);
    expect(find.text('Taxi · Yandex Go · 19 Sep, 23:10'), findsOneWidget);
    expect(find.text('Clear all filters'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('41 transactions'), findsOneWidget);
  });

  testApp('type chips become removable filters', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Remove filter Income'));
    await tester.pumpAndSettle();
    expect(find.text('41 transactions'), findsOneWidget);
  });

  testApp('sort by largest shows a flat list', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.tap(find.bySemanticsLabel('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Largest amount'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY · 30 SEP'), findsNothing, reason: 'flat list');
    expect(find.text('September salary · 30 Sep, 10:05'), findsOneWidget);
  });

  testApp('period chip switches to all time', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.tap(find.text('September'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.text('All time'), findsOneWidget);
    expect(find.textContaining(' transactions'), findsOneWidget);
    expect(find.text('41 transactions'), findsNothing);
  });

  testApp('category chip filters one category', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    // The chip row scrolls sideways; Category starts off screen.
    await tester.ensureVisible(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove filter Health'), findsOneWidget);
  });

  testApp('an empty month shows a message', (tester, db) async {
    await _openTab(tester);
    expect(find.textContaining('No transactions in'), findsOneWidget);
    expect(find.text('Search all time'), findsOneWidget);
  });

  testApp(
    'no results offers to clear filters or search all time',
    sampleData: true,
    (tester, db) async {
      await _openTab(tester);
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hotel');
      await tester.pumpAndSettle();

      expect(find.text('No matches for “hotel”'), findsOneWidget);
      expect(
        find.text(
          'Nothing in income for September matches this search. '
          'Try another word or remove a filter.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Search all time'));
      await tester.pumpAndSettle();
      expect(find.text('All time'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      // The search text stays; type and dates are reset.
      expect(find.bySemanticsLabel('Remove filter Income'), findsNothing);
      expect(find.text('No matches for “hotel”'), findsOneWidget);
    },
  );

  testApp('filter sheet applies type, category and sort', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Show 41 results'), findsOneWidget);

    final sheet = find.byType(BottomSheet);
    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Expenses')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Transportation'));
    await tester.pumpAndSettle();
    expect(find.text('Show 14 results'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Largest amount'),
      100,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    await tester.tap(find.bySemanticsLabel('Largest amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 14 results'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('14 results'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove filter Expenses'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Remove filter Transportation'),
      findsOneWidget,
    );
    expect(find.text('Largest'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Clear all filters'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Clear all filters'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('41 transactions'), findsOneWidget);
  });

  testApp('filter sheet date presets', sampleData: true, (tester, db) async {
    await _openTab(tester);
    await tester.tap(find.bySemanticsLabel('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('01 Sep 2026'), findsOneWidget);
    expect(find.text('30 Sep 2026'), findsOneWidget);

    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(find.text('01 Aug 2026'), findsOneWidget);
    expect(find.text('31 Aug 2026'), findsOneWidget);

    await tester.tap(find.text('3 months'));
    await tester.pumpAndSettle();
    expect(find.text('01 Jul 2026'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('01 Sep 2026'), findsOneWidget);
  });
}
