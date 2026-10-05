import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/format/money_format.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/backup/backup_service.dart';
import 'package:personal_finance/data/backup/file_io.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/features/categories/ui/categories_page.dart';

import '../../helpers/fake_settings_io.dart';
import '../../helpers/test_db.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings'));
  await tester.pumpAndSettle();
}

/// Scrolls to a settings row, clear of the floating bottom nav, and taps it.
Future<void> _tapRow(WidgetTester tester, String label) async {
  final row = find.text(label);
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(row, 200, scrollable: scrollable);
  final navTop = tester.getTopLeft(find.bySemanticsLabel('Home')).dy - 40;
  final bottom = tester.getBottomLeft(row).dy;
  if (bottom > navTop) {
    await tester.drag(scrollable, Offset(0, navTop - bottom - 20));
    await tester.pumpAndSettle();
  }
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<AppSettings> _saved(WidgetTester tester, db) async =>
    (await tester.runAsync(() => SettingsRepository(db).load()))!;

/// A backup of the sample data, made once for the restore test.
late String backupText;

void main() {
  setUpAll(() async {
    final source = memoryDb();
    await ensureDefaults(source);
    await seedSampleData(source);
    backupText = await BackupService(source).create();
    await source.close();
  });

  tearDown(() {
    // Global formats; reset for the next test in this file.
    MoneyFormat.style = NumberStyle.space;
    MonthCycle.startDay = 1;
  });

  testApp('shows the profile and every section', sampleData: true, (
    tester,
    db,
  ) async {
    await _openSettings(tester);
    expect(find.text('Ozodbek'), findsOneWidget);
    expect(find.textContaining('Tracking since April 2026 · '), findsOneWidget);
    expect(find.text('UZS · so’m'), findsOneWidget);
    expect(find.text('15 000 000'), findsOneWidget);
    expect(find.text('1st'), findsOneWidget);
    expect(find.text('Humo'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Version 1.0.0'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
  });

  testApp('edits the name', (tester, db) async {
    await _openSettings(tester);
    await tester.tap(find.text('Add your name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Aziza');
    await tester.pump(); // Let Save turn on.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Aziza'), findsOneWidget);
    expect((await _saved(tester, db)).userName, 'Aziza');
  });

  testApp('number format changes amounts everywhere', sampleData: true, (
    tester,
    db,
  ) async {
    await _openSettings(tester);
    await _tapRow(tester, 'Number format');
    await tester.tap(find.text('15,000,000'));
    await tester.pumpAndSettle();
    expect((await _saved(tester, db)).numberStyle, NumberStyle.comma);

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.text('15,500,000'), findsOneWidget);
  });

  testApp('month start day is saved', (tester, db) async {
    await _openSettings(tester);
    await _tapRow(tester, 'Month starts on');
    await tester.scrollUntilVisible(
      find.text('25th'),
      200,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.text('25th'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25th'));
    await tester.pumpAndSettle();
    expect(find.text('25th'), findsOneWidget);
    expect((await _saved(tester, db)).monthStartDay, 25);
    expect(MonthCycle.startDay, 25);
  });

  testApp('Manage rows open their pages', (tester, db) async {
    await _openSettings(tester);
    await _tapRow(tester, 'Categories');
    expect(find.byType(CategoriesPage), findsOneWidget);
  });

  final share = FakeShare();
  testApp(
    'exports transactions as CSV',
    sampleData: true,
    overrides: fakeSettingsOverrides(share: share),
    (tester, db) async {
      await _openSettings(tester);
      await _tapRow(tester, 'Export to CSV');
      final file = share.files.single;
      expect(file.fileName, 'personal_finance_transactions_2026-09-30.csv');
      expect(file.mimeType, 'text/csv');
      expect(file.content, startsWith('Date,Type,Category'));
    },
  );

  final backupShare = FakeShare();
  testApp(
    'creates a backup and remembers when',
    sampleData: true,
    overrides: fakeSettingsOverrides(share: backupShare),
    (tester, db) async {
      await _openSettings(tester);
      await _tapRow(tester, 'Backup & restore');
      await tester.tap(find.text('Create backup'));
      await tester.pumpAndSettle();
      expect(backupShare.files.single.fileName, endsWith('.json'));
      expect(find.text('Last: today'), findsOneWidget);
    },
  );

  testApp(
    'restores a backup after asking',
    overrides: [
      // Read lazily: the backup text is made in setUpAll.
      pickBackupTextProvider.overrideWithValue(() async => backupText),
    ],
    (tester, db) async {
      await _openSettings(tester);
      expect(find.text('Add your name'), findsOneWidget);

      await _tapRow(tester, 'Backup & restore');
      await tester.tap(find.text('Restore from file'));
      await tester.pumpAndSettle();
      expect(find.text('Replace all data?'), findsOneWidget);
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(find.text('Backup restored'), findsOneWidget);
      expect(find.text('Ozodbek'), findsOneWidget);
    },
  );

  final auth = FakeAuthenticator();
  testApp(
    'app lock asks for Face ID and locks after the background',
    overrides: fakeSettingsOverrides(auth: auth),
    (tester, db) async {
      await _openSettings(tester);
      await _tapRow(tester, 'App lock');
      expect(auth.prompts, 1);
      expect((await _saved(tester, db)).appLock, isTrue);

      // Going to the background locks. No frames are drawn while paused,
      // so use pump, not pumpAndSettle.
      auth.succeed = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(auth.prompts, 2, reason: 'asks again on return');
      expect(find.text('Personal Finance is locked'), findsOneWidget);

      auth.succeed = true;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Finance is locked'), findsNothing);
    },
  );

  final noLock = FakeAuthenticator()..available = false;
  testApp(
    'app lock needs a phone screen lock',
    overrides: fakeSettingsOverrides(auth: noLock),
    (tester, db) async {
      await _openSettings(tester);
      await _tapRow(tester, 'App lock');
      expect(
        find.text('Set up a screen lock on your phone first.'),
        findsOneWidget,
      );
      expect((await _saved(tester, db)).appLock, isFalse);
    },
  );
}
