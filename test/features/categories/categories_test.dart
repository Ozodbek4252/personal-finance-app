import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/features/categories/ui/categories_page.dart';
import 'package:personal_finance/features/categories/ui/category_form_page.dart';
import 'package:personal_finance/router.dart';

import '../../helpers/test_db.dart';

Future<void> _openCategories(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).push(Routes.categories);
  await tester.pumpAndSettle();
}

/// Category names of one kind in their saved order (archived left out).
Future<List<String>> _names(
  WidgetTester tester,
  AppDatabase db,
  TransactionKind kind,
) async {
  final rows = (await tester.runAsync(
    () =>
        (db.select(db.categories)
              ..where(
                (c) => c.kind.equalsValue(kind) & c.isArchived.equals(false),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
            .get(),
  ))!;
  return rows.map((c) => c.name).toList();
}

/// The main scrollable of the page on top ([page] is its widget type).
Finder _scrollableOf(Type page) => find
    .descendant(of: find.byType(page), matching: find.byType(Scrollable))
    .first;

void main() {
  testApp(
    'lists both kinds with counts and quick-add badges',
    sampleData: true,
    (tester, db) async {
      await _openCategories(tester);
      expect(find.byType(CategoriesPage), findsOneWidget);
      expect(find.text('EXPENSE CATEGORIES'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('14 this month'), findsOneWidget);
      expect(find.text('Quick add'), findsNWidgets(9));
    },
  );

  testApp('Edit on the add screen opens categories', (tester, db) async {
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPage), findsOneWidget);
  });

  testApp('dragging a row changes the order', (tester, db) async {
    await _openCategories(tester);
    final handle = find.bySemanticsLabel('Reorder Groceries');
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    final names = await _names(tester, db, TransactionKind.expense);
    expect(names.take(2), ['Groceries', 'Transportation']);
  });

  testApp('creates a category in the last quick-add slot', (tester, db) async {
    await _openCategories(tester);
    await tester.tap(find.bySemanticsLabel('New category').first);
    await tester.pumpAndSettle();
    expect(find.text('New category'), findsWidgets);
    expect(
      find.text('Replaces the last quick-add slot (Other)'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Gym');
    await tester.tap(find.bySemanticsLabel('dumbbell icon'));
    await tester.tap(find.bySemanticsLabel('blue color'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Create category'),
      200,
      scrollable: _scrollableOf(CategoryFormPage),
    );
    await tester.tap(find.text('Create category'));
    await tester.pumpAndSettle();

    expect(find.text('Category created'), findsOneWidget);
    final names = await _names(tester, db, TransactionKind.expense);
    expect(names[8], 'Gym');
    expect(names[9], 'Other');
    final gym = (await tester.runAsync(
      () => (db.select(
        db.categories,
      )..where((c) => c.name.equals('Gym'))).getSingle(),
    ))!;
    expect(gym.iconKey, 'dumbbell');
    expect(gym.colorKey, 'blue');
  });

  testApp('a new category can stay off the add screen', (tester, db) async {
    await _openCategories(tester);
    await tester.tap(find.bySemanticsLabel('New category').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pets');
    await tester.scrollUntilVisible(
      find.byType(Switch),
      200,
      scrollable: _scrollableOf(CategoryFormPage),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Create category'),
      200,
      scrollable: _scrollableOf(CategoryFormPage),
    );
    await tester.tap(find.text('Create category'));
    await tester.pumpAndSettle();
    final names = await _names(tester, db, TransactionKind.expense);
    expect(names.last, 'Pets');
  });

  testApp('duplicate names are not allowed', (tester, db) async {
    await _openCategories(tester);
    await tester.tap(find.bySemanticsLabel('New category').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'food');
    await tester.pump();
    expect(
      find.text('You already have a category with this name.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Category created'), findsNothing);
  });

  testApp('edit renames, remove archives', (tester, db) async {
    await _openCategories(tester);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Edit Rent'),
      200,
      scrollable: _scrollableOf(CategoriesPage),
    );
    await tester.tap(find.bySemanticsLabel('Edit Rent'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
    expect(find.text('Show on add screen'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Home rent');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Category saved'), findsOneWidget);
    expect(
      await _names(tester, db, TransactionKind.expense),
      contains('Home rent'),
    );

    // Let the "Category saved" message go away; it floats over buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Edit Entertainment'),
      200,
      scrollable: _scrollableOf(CategoriesPage),
    );
    await tester.tap(find.bySemanticsLabel('Edit Entertainment'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Remove category'),
      200,
      scrollable: _scrollableOf(CategoryFormPage),
    );
    await tester.tap(find.text('Remove category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      await _names(tester, db, TransactionKind.expense),
      isNot(contains('Entertainment')),
    );
  });
}
