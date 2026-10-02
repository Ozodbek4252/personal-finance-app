import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/app.dart';

void main() {
  testWidgets('app starts and switches to dark theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonalFinanceApp()));

    expect(find.text('Design preview'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Design preview'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
