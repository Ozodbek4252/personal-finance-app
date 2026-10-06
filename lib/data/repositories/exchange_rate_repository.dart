import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/currency.dart';

/// Keeps official (CBU) rates, one per currency and day.
class ExchangeRateRepository {
  ExchangeRateRepository(this._db);

  final AppDatabase _db;

  /// Saves the rate for [day]. A second save for the same day replaces
  /// the first one.
  Future<void> save(Currency currency, DateTime day, double rate) async {
    await _db
        .into(_db.exchangeRates)
        .insertOnConflictUpdate(
          ExchangeRatesCompanion.insert(
            currency: currency,
            day: DateTime(day.year, day.month, day.day),
            rate: rate,
          ),
        );
  }

  /// The newest saved rate, or null when none is saved yet.
  Stream<ExchangeRateRow?> watchLatest(Currency currency) {
    final query = _db.select(_db.exchangeRates)
      ..where((r) => r.currency.equalsValue(currency))
      ..orderBy([(r) => OrderingTerm.desc(r.day)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// Saved rates from [from] on, oldest first. Used for the rate chart.
  Stream<List<ExchangeRateRow>> watchSince(Currency currency, DateTime from) {
    final query = _db.select(_db.exchangeRates)
      ..where(
        (r) =>
            r.currency.equalsValue(currency) & r.day.isBiggerOrEqualValue(from),
      )
      ..orderBy([(r) => OrderingTerm.asc(r.day)]);
    return query.watch();
  }
}
