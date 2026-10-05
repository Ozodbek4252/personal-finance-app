import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/format/money_format.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/backup/backup_service.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/settings/domain/csv_export.dart';
import 'package:personal_finance/features/settings/ui/settings_page.dart';

import '../../helpers/test_db.dart';

void main() {
  group('month start day', () {
    tearDown(() => MonthCycle.startDay = 1);

    test('months can start on the 25th', () {
      MonthCycle.startDay = 25;
      expect(monthStart(DateTime(2026, 9, 30)), DateTime(2026, 9, 25));
      expect(monthStart(DateTime(2026, 9, 24, 23)), DateTime(2026, 8, 25));
      expect(nextMonthStart(DateTime(2026, 9, 30)), DateTime(2026, 10, 25));
      expect(shiftMonths(DateTime(2026, 1, 25), -1), DateTime(2025, 12, 25));
    });

    test('default is calendar months', () {
      expect(monthStart(DateTime(2026, 9, 30, 15)), DateTime(2026, 9));
      expect(nextMonthStart(DateTime(2026, 12, 3)), DateTime(2027));
    });
  });

  test('number styles', () {
    addTearDown(() => MoneyFormat.style = NumberStyle.space);
    MoneyFormat.style = NumberStyle.comma;
    expect(MoneyFormat.amount(15000000), '15,000,000');
    MoneyFormat.style = NumberStyle.dot;
    expect(MoneyFormat.signed(-420000), '−420.000');
    expect(MoneyFormat.parseDigits('420.000'), 420000);
  });

  test('ordinal day names', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 28].map(ordinal), [
      '1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', //
      '28th',
    ]);
  });

  group('with sample data', () {
    late AppDatabase db;
    late TransactionRepository repo;

    setUp(() async {
      db = memoryDb();
      repo = TransactionRepository(db, const SystemClock());
      await ensureDefaults(db);
      await seedSampleData(db);
    });
    tearDown(() => db.close());

    test('CSV has a header, one row each, and quotes commas', () async {
      final items = await repo
          .watchBetween(DateTime(2026, 9), DateTime(2026, 10))
          .first;
      final csv = buildTransactionsCsv(items);
      final lines = csv.trim().split('\r\n');
      expect(lines.first, startsWith('Date,Type,Category,Amount (UZS)'));
      expect(lines, hasLength(items.length + 1));
      expect(
        lines[1],
        '2026-09-30 13:40,Expense,Groceries,-420000,Uzcard,Korzinka,'
        '"Weekly groceries, cleaning supplies and bread"',
      );
    });

    test('backup and restore bring everything back', () async {
      final service = BackupService(db);
      final text = await service.create();
      final before = await db.transactions.count().getSingle();

      await db.delete(db.transactions).go();
      await (db.update(db.categories)..where((c) => c.name.equals('Food')))
          .write(const CategoriesCompanion(name: Value('Meals')));

      await service.restore(text);
      expect(await db.transactions.count().getSingle(), before);
      final food = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('Food'))).getSingleOrNull();
      expect(food, isNotNull);
      expect((await SettingsRepository(db).load()).sampleDataSeeded, isTrue);
    });

    test('bad files are refused and change nothing', () async {
      final service = BackupService(db);
      final before = await db.transactions.count().getSingle();
      await expectLater(
        service.restore('not json'),
        throwsA(isA<BackupFormatException>()),
      );
      await expectLater(
        service.restore('{"app": "other"}'),
        throwsA(isA<BackupFormatException>()),
      );
      await expectLater(
        service.restore(
          '{"app": "personal_finance", "version": 1, '
          '"transactions": [{"bad": true}]}',
        ),
        throwsA(isA<BackupFormatException>()),
      );
      expect(await db.transactions.count().getSingle(), before);
    });
  });
}
