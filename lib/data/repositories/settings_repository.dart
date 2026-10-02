import 'package:flutter/material.dart' show ThemeMode;

import '../db/app_database.dart';

/// Names of the stored settings.
abstract final class SettingKeys {
  static const themeMode = 'theme_mode';
  static const defaultPaymentMethodId = 'default_payment_method_id';
  static const balanceHidden = 'balance_hidden';
  static const userName = 'user_name';

  /// Set after sample data is added once, so it is not added again
  /// when the user deletes everything.
  static const sampleDataSeeded = 'sample_data_seeded';
}

/// Typed, read-only view of the stored settings.
class AppSettings {
  const AppSettings(this._values);

  static const empty = AppSettings({});

  final Map<String, String> _values;

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _values[SettingKeys.themeMode],
    orElse: () => ThemeMode.system,
  );

  int? get defaultPaymentMethodId =>
      int.tryParse(_values[SettingKeys.defaultPaymentMethodId] ?? '');

  bool get balanceHidden => _values[SettingKeys.balanceHidden] == 'true';

  String? get userName => _values[SettingKeys.userName];

  bool get sampleDataSeeded => _values[SettingKeys.sampleDataSeeded] == 'true';
}

/// Reads and writes settings in the key-value `settings` table.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async =>
      AppSettings(_toMap(await _db.select(_db.settings).get()));

  Stream<AppSettings> watch() =>
      _db.select(_db.settings).watch().map((rows) => AppSettings(_toMap(rows)));

  Future<void> set(String key, String value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(SettingRow(key: key, value: value));
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      set(SettingKeys.themeMode, mode.name);

  Future<void> setDefaultPaymentMethod(int id) =>
      set(SettingKeys.defaultPaymentMethodId, '$id');

  Future<void> setBalanceHidden(bool hidden) =>
      set(SettingKeys.balanceHidden, '$hidden');

  static Map<String, String> _toMap(List<SettingRow> rows) => {
    for (final r in rows) r.key: r.value,
  };
}
