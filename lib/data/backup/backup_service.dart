import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../repositories/settings_repository.dart';

/// Thrown when a file is not a backup of this app.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Saves all data as one JSON text, and restores it again.
///
/// Receipt photos are not part of a backup; only their file names are.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _app = 'personal_finance';
  static const _version = 1;

  Future<String> create() async {
    final data = {
      'app': _app,
      'version': _version,
      'createdAt': DateTime.now().toIso8601String(),
      'categories': [
        for (final r in await _db.select(_db.categories).get()) r.toJson(),
      ],
      'paymentMethods': [
        for (final r in await _db.select(_db.paymentMethods).get()) r.toJson(),
      ],
      'transactions': [
        for (final r in await _db.select(_db.transactions).get()) r.toJson(),
      ],
      'settings': [
        for (final r in await _db.select(_db.settings).get()) r.toJson(),
      ],
    };
    return const JsonEncoder.withIndent(' ').convert(data);
  }

  /// Replaces all data with the backup. Nothing changes if the text is
  /// not a valid backup.
  Future<void> restore(String text) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('This file is not a backup.');
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != _app) {
      throw const BackupFormatException('This file is not a backup.');
    }
    if (decoded['version'] != _version) {
      throw const BackupFormatException(
        'This backup was made by a newer app version.',
      );
    }

    List<Map<String, dynamic>> list(String key) =>
        (decoded as Map<String, dynamic>)[key] is List
        ? [
            for (final item in decoded[key] as List)
              item as Map<String, dynamic>,
          ]
        : const [];

    // Parse everything first, so a broken file changes nothing.
    final List<CategoryRow> categories;
    final List<PaymentMethodRow> methods;
    final List<TransactionRow> transactions;
    final List<SettingRow> settings;
    try {
      categories = list('categories').map(CategoryRow.fromJson).toList();
      methods = list('paymentMethods').map(PaymentMethodRow.fromJson).toList();
      transactions = list('transactions').map(TransactionRow.fromJson).toList();
      settings = list('settings').map(SettingRow.fromJson).toList();
    } on Object {
      throw const BackupFormatException('This backup file is damaged.');
    }

    await _db.transaction(() async {
      // Children first, because transactions point to the other tables.
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.paymentMethods).go();
      await _db.delete(_db.settings).go();
      await _db.batch((b) {
        b.insertAll(_db.categories, categories);
        b.insertAll(_db.paymentMethods, methods);
        b.insertAll(_db.transactions, transactions);
        b.insertAll(_db.settings, settings);
        // Never add sample data on top of restored data.
        b.insert(
          _db.settings,
          const SettingRow(key: SettingKeys.sampleDataSeeded, value: 'true'),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }
}
