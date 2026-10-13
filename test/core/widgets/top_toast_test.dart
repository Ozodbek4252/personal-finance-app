import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/theme/app_theme.dart';
import 'package:personal_finance/core/widgets/top_toast.dart';

void main() {
  late BuildContext ctx;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold();
          },
        ),
      ),
    );
  }

  testWidgets('shows at the top and goes away after 4 seconds', (
    tester,
  ) async {
    await pumpApp(tester);
    showToast(ctx, 'Changes saved');
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Changes saved')).dy, lessThan(80));

    await tester.pump(TopToast.duration);
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsNothing);
  });

  testWidgets('the action runs and closes the message', (tester) async {
    await pumpApp(tester);
    var undone = false;
    TopToast.of(
      ctx,
    ).show('Expense saved', actionLabel: 'Undo', onAction: () => undone = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Expense saved'), findsNothing);
  });

  testWidgets('swiping up closes it; a new one replaces the old', (
    tester,
  ) async {
    await pumpApp(tester);
    showToast(ctx, 'First');
    await tester.pumpAndSettle();
    showToast(ctx, 'Second');
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    await tester.fling(find.text('Second'), const Offset(0, -200), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });
}
