import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/app.dart';

void main() {
  testWidgets('app starts and switches to dark theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonalFinanceApp()));

    expect(find.text('Design tokens'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Design tokens'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
