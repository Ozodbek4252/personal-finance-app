import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/app.dart';
import 'package:personal_finance/core/icons/app_icons.dart';
import 'package:personal_finance/core/theme/app_theme.dart';
import 'package:personal_finance/core/widgets/amount_text.dart';
import 'package:personal_finance/core/widgets/app_chip.dart';
import 'package:personal_finance/core/widgets/progress_bar.dart';
import 'package:personal_finance/core/widgets/segmented_tabs.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AmountText', () {
    testWidgets('shows sign, grouped digits and unit', (tester) async {
      await tester.pumpWidget(_wrap(const AmountText(-420000)));
      expect(find.text('−420 000'), findsOneWidget);
      expect(find.text('UZS'), findsOneWidget);

      await tester.pumpWidget(_wrap(const AmountText(15000000, signed: true)));
      expect(find.text('+15 000 000'), findsOneWidget);
    });

    testWidgets('hides the number', (tester) async {
      await tester.pumpWidget(_wrap(const AmountText(12450000, hidden: true)));
      expect(find.text('••••••'), findsOneWidget);
    });
  });

  testWidgets('SegmentedTabs reports the tapped value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 300,
          child: SegmentedTabs<String>(
            options: const [
              SegmentOption('w', 'Week'),
              SegmentOption('m', 'Month'),
            ],
            selected: 'm',
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Week'));
    expect(picked, 'w');
  });

  testWidgets('AppChip is tappable and marks selection', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        AppChip(
          label: 'Humo',
          selected: true,
          leadingIcon: AppIcons.card,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Humo'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(AppChip)),
      isSemantics(
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        label: 'Humo',
      ),
    );
  });

  testWidgets('ProgressBar clamps values above 1', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(width: 200, child: ProgressBar(value: 1.7, marker: 0.5)),
      ),
    );
    final fill = tester.getSize(
      find
          .descendant(
            of: find.byType(ProgressBar),
            matching: find.byType(DecoratedBox),
          )
          .at(1),
    );
    expect(fill.width, 200);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'preview tabs render at phone width (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const ProviderScope(child: PersonalFinanceApp()),
        );
        if (dark) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
        }
        for (final tab in ['Icons', 'Widgets']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
        }
        // Scroll through the widget gallery; overflow errors fail the test.
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(find.text('Disabled'), findsOneWidget);
      },
    );
  }
}
