import 'package:drift/drift.dart';

import '../../core/time/clock.dart';
import '../models/currency.dart';
import '../models/transaction_kind.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transaction_repository.dart';
import 'app_database.dart';

/// Default categories, in the design's order: (name, icon, color).
const _expenseCategories = [
  ('Transportation', 'car', 'blue'),
  ('Groceries', 'cart', 'green'),
  ('Food', 'food', 'orange'),
  ('Shopping', 'bag', 'purple'),
  ('Bills', 'receipt', 'teal'),
  ('Health', 'heart', 'red'),
  ('Education', 'cap', 'indigo'),
  ('Emergency', 'alert', 'amber'),
  ('Other', 'box', 'gray'),
  ('Rent', 'home', 'brown'),
  ('Entertainment', 'film', 'pink'),
];

const _incomeCategories = [
  ('Salary', 'wallet', 'emerald'),
  ('Advance', 'cash', 'teal'),
  ('Bonus', 'star', 'amber'),
  ('Freelance', 'laptop', 'blue'),
  ('Gift', 'gift', 'pink'),
  ('Other', 'box', 'gray'),
];

/// Default payment methods: (name, icon, is custom, currency).
const _paymentMethods = [
  ('Cash', 'cash', false, Currency.uzs),
  ('Humo', 'card', false, Currency.uzs),
  ('Uzcard', 'card', false, Currency.uzs),
  ('Visa', 'card', false, Currency.uzs),
  ('Mastercard', 'card', false, Currency.uzs),
  ('Bank transfer', 'bank', false, Currency.uzs),
  ('Click wallet', 'phone', true, Currency.uzs),
  ('Other', 'box', false, Currency.uzs),
  ('Cash (USD)', 'cash', false, Currency.usd),
];

/// Adds the default categories and payment methods on first start.
/// Does nothing if categories already exist.
Future<void> ensureDefaults(AppDatabase db) async {
  final count = await db.categories.count().getSingle();
  if (count > 0) return;

  await db.transaction(() async {
    await db.batch((b) {
      for (final (i, c) in _expenseCategories.indexed) {
        b.insert(db.categories, _category(c, TransactionKind.expense, i));
      }
      for (final (i, c) in _incomeCategories.indexed) {
        b.insert(db.categories, _category(c, TransactionKind.income, i));
      }
      for (final (i, m) in _paymentMethods.indexed) {
        b.insert(
          db.paymentMethods,
          PaymentMethodsCompanion.insert(
            name: m.$1,
            iconKey: m.$2,
            isCustom: Value(m.$3),
            sortOrder: i,
            currency: Value(m.$4),
          ),
        );
      }
    });
    final humo = await (db.select(
      db.paymentMethods,
    )..where((m) => m.name.equals('Humo'))).getSingle();
    await SettingsRepository(db).setDefaultPaymentMethod(humo.id);
  });
}

CategoriesCompanion _category(
  (String, String, String) c,
  TransactionKind kind,
  int order,
) => CategoriesCompanion.insert(
  name: c.$1,
  kind: kind,
  iconKey: c.$2,
  colorKey: c.$3,
  sortOrder: order,
);

/// "Today" in the sample data. Debug builds pin the clock to it.
final sampleToday = DateTime(2026, 9, 30, 15);

/// Adds the design's sample data: September 2026 in detail and
/// April–August 2026 as history. The month totals match the
/// Monthly overview and Statistics boards.
///
/// Runs only once per database (see [SettingKeys.sampleDataSeeded]).
Future<void> seedSampleData(AppDatabase db) async {
  final settings = SettingsRepository(db);
  if ((await settings.load()).sampleDataSeeded) return;

  await db.transaction(() async {
    final ids = await _Ids.load(db);
    final rows = <TransactionsCompanion>[
      ..._september(ids),
      for (final plan in _historyPlans) ...plan.build(ids),
    ];
    await db.batch((b) => b.insertAll(db.transactions, rows));
    await _seedDollars(db);
    await _coverNegativeBalances(db);
    await settings.set(SettingKeys.userName, 'Ozodbek');
    await settings.set(SettingKeys.sampleDataSeeded, 'true');
  });
}

/// The design's dollar savings: $500 bought in three exchanges
/// ($300 in Cash (USD), $200 on a Visa USD card), plus six months of
/// CBU rates for the rate chart.
Future<void> _seedDollars(AppDatabase db) async {
  final ids = await _Ids.load(db);
  final visaUsd = await PaymentMethodRepository(
    db,
  ).addCustom('Visa USD card', iconKey: 'card', currency: Currency.usd);
  final exchanges = [
    // (day, dollars, rate, to)
    (DateTime(2026, 8, 18, 14, 20), 200, 12470.0, ids.method('Cash (USD)')),
    (DateTime(2026, 9, 12, 10, 5), 200, 12560.0, visaUsd),
    (DateTime(2026, 9, 30, 11, 30), 100, 12650.0, ids.method('Cash (USD)')),
  ];
  await db.batch((b) {
    for (final (at, dollars, rate, to) in exchanges) {
      b.insert(
        db.exchanges,
        ExchangesCompanion.insert(
          fromMethodId: ids.method('Humo'),
          fromAmount: (dollars * rate).round(),
          toMethodId: to,
          toAmount: dollars * Currency.usd.minorUnits,
          rate: rate,
          occurredAt: at,
          createdAt: at.add(const Duration(minutes: 1)),
          updatedAt: at.add(const Duration(minutes: 1)),
        ),
      );
    }
    // Monthly points for the "USD rate · 6 months" chart.
    for (final (month, rate) in const [
      (4, 12410.0),
      (5, 12470.0),
      (6, 12520.0),
      (7, 12480.0),
      (8, 12560.0),
    ]) {
      b.insert(
        db.exchangeRates,
        ExchangeRatesCompanion.insert(
          currency: Currency.usd,
          day: DateTime(2026, month, 15),
          rate: rate,
        ),
      );
    }
    b.insert(
      db.exchangeRates,
      ExchangeRatesCompanion.insert(
        currency: Currency.usd,
        day: DateTime(2026, 9, 30),
        rate: 12650,
      ),
    );
  });
}

/// Gives a starting balance to so'm methods that would be below zero,
/// the way real cash was there before tracking started.
Future<void> _coverNegativeBalances(AppDatabase db) async {
  final balances = await TransactionRepository(
    db,
    const SystemClock(),
  ).getBalances();
  for (final MapEntry(key: id, value: net) in balances.entries) {
    if (net >= 0) continue;
    // Round up to the next 100 000 and keep 500 000 left over.
    final opening = ((-net + 99999) ~/ 100000) * 100000 + 500000;
    await (db.update(db.paymentMethods)..where((m) => m.id.equals(id))).write(
      PaymentMethodsCompanion(openingBalance: Value(opening)),
    );
  }
}

/// Looks up category and payment method ids by name.
class _Ids {
  _Ids(this._expense, this._income, this._methods);

  final Map<String, int> _expense;
  final Map<String, int> _income;
  final Map<String, int> _methods;

  static Future<_Ids> load(AppDatabase db) async {
    final cats = await db.select(db.categories).get();
    final methods = await db.select(db.paymentMethods).get();
    return _Ids(
      {
        for (final c in cats)
          if (c.kind == TransactionKind.expense) c.name: c.id,
      },
      {
        for (final c in cats)
          if (c.kind == TransactionKind.income) c.name: c.id,
      },
      {for (final m in methods) m.name: m.id},
    );
  }

  int category(TransactionKind kind, String name) =>
      (kind == TransactionKind.expense ? _expense : _income)[name]!;

  int method(String name) => _methods[name]!;
}

TransactionsCompanion _row(
  _Ids ids, {
  required TransactionKind kind,
  required String category,
  required int amount,
  required String method,
  required DateTime at,
  String? note,
  String? description,
}) => TransactionsCompanion.insert(
  kind: kind,
  amount: amount,
  categoryId: ids.category(kind, category),
  paymentMethodId: ids.method(method),
  occurredAt: at,
  note: Value(note),
  description: Value(description),
  // Pretend each one was typed in a minute after it happened.
  createdAt: at.add(const Duration(minutes: 1)),
  updatedAt: at.add(const Duration(minutes: 1)),
);

const _e = TransactionKind.expense;
const _i = TransactionKind.income;

/// September 2026: the rows shown on the boards, plus filler rows so
/// each category reaches its total and count from the design.
List<TransactionsCompanion> _september(_Ids ids) {
  DateTime d(int day, int h, int m) => DateTime(2026, 9, day, h, m);
  final shown = [
    _row(
      ids,
      kind: _e,
      category: 'Groceries',
      amount: 420000,
      method: 'Uzcard',
      at: d(30, 13, 40),
      note: 'Korzinka',
      description: 'Weekly groceries, cleaning supplies and bread',
    ),
    _row(
      ids,
      kind: _i,
      category: 'Salary',
      amount: 15000000,
      method: 'Bank transfer',
      at: d(30, 10, 5),
      note: 'September salary',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Transportation',
      amount: 35000,
      method: 'Humo',
      at: d(30, 9, 12),
      note: 'Taxi · Yandex Go',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Bills',
      amount: 120000,
      method: 'Humo',
      at: d(29, 18, 4),
      note: 'Home internet',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Food',
      amount: 85000,
      method: 'Cash',
      at: d(29, 13, 20),
      note: 'Lunch at Rayhon',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Transportation',
      amount: 28000,
      method: 'Cash',
      at: d(28, 19, 40),
      note: 'Taxi · MyTaxi',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Emergency',
      amount: 500000,
      method: 'Cash',
      at: d(27, 16, 30),
      note: 'Phone screen repair',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Shopping',
      amount: 350000,
      method: 'Visa',
      at: d(27, 12, 15),
      note: 'Running shoes',
    ),
    _row(
      ids,
      kind: _i,
      category: 'Freelance',
      amount: 500000,
      method: 'Bank transfer',
      at: d(25, 20, 10),
      note: 'Landing page fix',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Groceries',
      amount: 96000,
      method: 'Humo',
      at: d(25, 19, 2),
      note: 'Makro',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Transportation',
      amount: 42000,
      method: 'Humo',
      at: d(24, 8, 55),
      note: 'Taxi · Yandex Go',
    ),
    _row(
      ids,
      kind: _e,
      category: 'Transportation',
      amount: 43000,
      method: 'Humo',
      at: d(19, 23, 10),
      note: 'Taxi · Yandex Go',
    ),
  ];

  // Filler days skip 25–30, so the newest part of the list matches the
  // Transaction history board.
  final filler = _MonthPlan(
    2026,
    9,
    maxDay: 24,
    expenses: const {
      'Groceries': (304000, 4),
      'Shopping': (120000, 2),
      'Transportation': (262000, 10),
      'Food': (295000, 8),
      'Bills': (170000, 3),
      'Health': (180000, 2),
    },
    incomes: const [],
  );
  return [...shown, ...filler.build(ids)];
}

/// April–August 2026. Totals per month match the Monthly overview board:
/// Apr 14.0M / 3.48M, May 14.0M / 3.72M, Jun 15.2M / 4.65M,
/// Jul 14.5M / 3.9M, Aug 15.0M / 4.28M (income / expenses).
/// Transportation matches the Statistics category trend.
const _historyPlans = [
  _MonthPlan(
    2026,
    4,
    expenses: {
      'Transportation': (290000, 10),
      'Groceries': (900000, 5),
      'Food': (420000, 8),
      'Shopping': (600000, 3),
      'Bills': (280000, 4),
      'Health': (150000, 2),
      'Entertainment': (200000, 2),
      'Other': (640000, 2),
    },
    incomes: [('Salary', 14000000, 30)],
  ),
  _MonthPlan(
    2026,
    5,
    expenses: {
      'Transportation': (320000, 11),
      'Groceries': (950000, 5),
      'Food': (450000, 8),
      'Shopping': (520000, 3),
      'Bills': (285000, 4),
      'Health': (210000, 2),
      'Entertainment': (250000, 2),
      'Education': (735000, 1),
    },
    incomes: [('Salary', 14000000, 29)],
  ),
  _MonthPlan(
    2026,
    6,
    expenses: {
      'Transportation': (365000, 12),
      'Groceries': (1020000, 6),
      'Food': (510000, 9),
      'Shopping': (1150000, 4),
      'Bills': (290000, 4),
      'Health': (340000, 3),
      'Entertainment': (300000, 3),
      'Emergency': (675000, 1),
    },
    incomes: [('Salary', 14000000, 30), ('Bonus', 1200000, 15)],
  ),
  _MonthPlan(
    2026,
    7,
    expenses: {
      'Transportation': (300000, 11),
      'Groceries': (980000, 5),
      'Food': (460000, 8),
      'Shopping': (540000, 3),
      'Bills': (290000, 4),
      'Health': (160000, 2),
      'Entertainment': (250000, 2),
      'Other': (920000, 2),
    },
    incomes: [('Salary', 14000000, 30), ('Freelance', 500000, 20)],
  ),
  _MonthPlan(
    2026,
    8,
    expenses: {
      'Transportation': (347000, 12),
      'Groceries': (1050000, 6),
      'Food': (520000, 9),
      'Shopping': (760000, 4),
      'Bills': (290000, 4),
      'Health': (230000, 2),
      'Entertainment': (180000, 2),
      'Education': (903000, 1),
    },
    incomes: [('Salary', 15000000, 29)],
  ),
];

/// One month of generated transactions. Each expense category gets
/// (total, count); the total is split into uneven parts on spread-out
/// days, so charts look natural but the sums are exact.
class _MonthPlan {
  const _MonthPlan(
    this.year,
    this.month, {
    required this.expenses,
    required this.incomes,
    this.maxDay = 28,
  });

  final int year;
  final int month;
  final Map<String, (int, int)> expenses;

  /// (category, amount, day of month).
  final List<(String, int, int)> incomes;
  final int maxDay;

  static const _weights = [1.15, 0.85, 1.3, 0.7, 1.0, 1.2, 0.8, 1.1, 0.9, 1.05];
  static const _times = [
    (9, 12),
    (12, 40),
    (18, 5),
    (13, 20),
    (20, 15),
    (8, 30),
    (15, 45),
    (19, 10),
    (11, 25),
    (17, 50),
  ];
  static const _methods = [
    'Humo',
    'Uzcard',
    'Cash',
    'Humo',
    'Click wallet',
    'Visa',
    'Cash',
    'Humo',
  ];
  static const _notes = {
    'Transportation': ['Metro', 'Bus ticket', 'Fuel', 'Parking'],
    'Groceries': ['Korzinka', 'Makro', 'Havas', 'Bazaar'],
    'Food': ['Lunch', 'Coffee', 'Evos', 'Bakery', 'Dinner with friends'],
    'Shopping': ['Clothes', 'Home goods', 'Gadget case'],
    'Bills': ['Electricity', 'Mobile plan', 'Gas', 'Water'],
    'Health': ['Pharmacy', 'Dentist', 'Check-up'],
    'Entertainment': ['Cinema', 'Concert ticket'],
    'Education': ['English course', 'Online course'],
    'Emergency': ['Car repair'],
    'Other': ['Gift for a friend', 'Household repair'],
  };

  List<TransactionsCompanion> build(_Ids ids) {
    final rows = <TransactionsCompanion>[];
    var n = 0; // Running index, so each row gets a different day and time.
    for (final MapEntry(key: category, value: (total, count))
        in expenses.entries) {
      final parts = splitAmount(total, count, offset: n);
      for (final (i, amount) in parts.indexed) {
        final day = 1 + (n * 7 + i * 3) % maxDay;
        final (h, m) = _times[n % _times.length];
        final notes = _notes[category]!;
        rows.add(
          _row(
            ids,
            kind: _e,
            category: category,
            amount: amount,
            method: _methods[n % _methods.length],
            at: DateTime(year, month, day, h, m),
            note: notes[i % notes.length],
          ),
        );
        n++;
      }
    }
    for (final (category, amount, day) in incomes) {
      rows.add(
        _row(
          ids,
          kind: _i,
          category: category,
          amount: amount,
          method: category == 'Salary' ? 'Humo' : 'Bank transfer',
          at: DateTime(year, month, day, 10, 5),
          note: category == 'Salary' ? 'Monthly salary' : null,
        ),
      );
    }
    return rows;
  }
}

/// Splits [total] into [count] uneven parts, each rounded to 1 000.
/// The last part takes the remainder, so the sum is exact.
List<int> splitAmount(int total, int count, {int offset = 0}) {
  if (count == 1) return [total];
  const w = _MonthPlan._weights;
  final weights = [for (var i = 0; i < count; i++) w[(i + offset) % w.length]];
  final sum = weights.reduce((a, b) => a + b);
  final parts = <int>[];
  var used = 0;
  for (var i = 0; i < count - 1; i++) {
    final part = (total * weights[i] / sum / 1000).round() * 1000;
    parts.add(part);
    used += part;
  }
  parts.add(total - used);
  return parts;
}
