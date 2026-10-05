import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

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

  testApp('search narrows the list and can be cleared', sampleData: true, (
    tester,
    db,
  ) async {
    await _openTab(tester);
    await tester.enterText(find.byType(TextField), 'taxi');
    await tester.pumpAndSettle();
    expect(find.text('4 transactions'), findsOneWidget);
    // Out and Net are both −148 000 when only expenses match.
    expect(find.text('−148 000'), findsNWidgets(2));

    await tester.tap(find.bySemanticsLabel('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('41 transactions'), findsOneWidget);
  });

  testApp('type chips and sort', sampleData: true, (tester, db) async {
    await _openTab(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('2 transactions'), findsOneWidget);

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
    expect(find.text('2 transactions'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
  });

  testApp('empty filters show a message', (tester, db) async {
    await _openTab(tester);
    expect(find.text('No transactions match these filters.'), findsOneWidget);
  });
}
