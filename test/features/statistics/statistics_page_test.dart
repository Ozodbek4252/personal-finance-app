import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

Future<void> _openTab(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Statistics'));
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testApp('month view matches the design', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('80.3%'), findsOneWidget);
    expect(
      find.text('Marker shows August (71.5%) · +8.9 pts this month'),
      findsOneWidget,
    );

    await _scrollTo(tester, find.text('Total spent'));
    expect(find.text('Groceries'), findsWidgets);

    await _scrollTo(tester, find.text('Decreasing'));
    expect(find.text('28.7% less than August'), findsOneWidget);
    await _scrollTo(tester, find.text('6-month average · 3 847 000 UZS'));

    await _scrollTo(tester, find.text('Transportation in September'));
    expect(find.text('18% vs Aug'), findsOneWidget);
    await _scrollTo(
      tester,
      find.text('6-month average · 339 000 UZS · 14 transactions this month'),
    );
  });

  testApp('arrows move between months', sampleData: true, (tester, db) async {
    await _openTab(tester);
    // Can't go past the current month.
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('71.5%'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
  });

  testApp('week and year tabs', sampleData: true, (tester, db) async {
    await _openTab(tester);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('28 Sep – 4 Oct 2026'), findsOneWidget);
    await _scrollTo(tester, find.text('Weekly spending trend'));

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('2026'), findsWidgets);
    expect(find.bySemanticsLabel('Previous year'), findsOneWidget);
  });

  testApp('empty data shows notes instead of charts', (tester, db) async {
    await _openTab(tester);
    expect(find.text('No spending in September.'), findsNothing);
    expect(find.textContaining('No spending in '), findsWidgets);
  });

  testApp('Monthly button opens the monthly overview', (tester, db) async {
    await _openTab(tester);
    await tester.tap(find.bySemanticsLabel('Monthly overview'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
  });
}
