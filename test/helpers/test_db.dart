import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:personal_finance/app.dart';
import 'package:personal_finance/data/bootstrap.dart';
import 'package:personal_finance/data/db/app_database.dart';

/// A fresh database that lives in memory only.
AppDatabase memoryDb() {
  // Each test opens its own database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      // Widget tests fail if drift's clean-up timers are still pending.
      closeStreamsSynchronously: true,
    ),
  );
}

/// Like `testWidgets`, but first pumps the whole app on a 390 × 844
/// screen with an in-memory database, and cleans up at the end.
@isTest
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  bool sampleData = false,
}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = memoryDb();
    // Database work runs outside the fake test clock.
    final overrides = (await tester.runAsync(
      () => bootstrap(db, sampleData: sampleData),
    ))!;
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const PersonalFinanceApp()),
    );
    await tester.pumpAndSettle();

    try {
      await body(tester, db);
    } finally {
      // Remove the app first, so no stream is still listening, then
      // close the database. This must happen inside the test, because
      // pending timers are checked before tear-down runs.
      await tester.pumpWidget(const SizedBox());
      await db.close();
    }
  });
}
