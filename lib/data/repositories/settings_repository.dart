import 'package:flutter/material.dart' show ThemeMode;

import '../../core/format/money_format.dart';
import '../db/app_database.dart';

/// Names of the stored settings.
abstract final class SettingKeys {
  static const themeMode = 'theme_mode';
  static const defaultPaymentMethodId = 'default_payment_method_id';
  static const balanceHidden = 'balance_hidden';
  static const userName = 'user_name';
  static const numberStyle = 'number_style';
  static const monthStartDay = 'month_start_day';
  static const appLock = 'app_lock';

  /// When the last backup file was made (ISO 8601).
  static const lastBackupAt = 'last_backup_at';

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

  NumberStyle get numberStyle => NumberStyle.values.firstWhere(
    (s) => s.name == _values[SettingKeys.numberStyle],
    orElse: () => NumberStyle.space,
  );

  /// 1–28. Other values fall back to 1.
  int get monthStartDay {
    final day = int.tryParse(_values[SettingKeys.monthStartDay] ?? '') ?? 1;
    return day >= 1 && day <= 28 ? day : 1;
  }

  bool get appLock => _values[SettingKeys.appLock] == 'true';

  DateTime? get lastBackupAt =>
      DateTime.tryParse(_values[SettingKeys.lastBackupAt] ?? '');

  /// All stored values, for backups.
  Map<String, String> get values => Map.unmodifiable(_values);
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

  Future<void> setUserName(String name) =>
      set(SettingKeys.userName, name.trim());

  Future<void> setNumberStyle(NumberStyle style) =>
      set(SettingKeys.numberStyle, style.name);

  Future<void> setMonthStartDay(int day) =>
      set(SettingKeys.monthStartDay, '${day.clamp(1, 28)}');

  Future<void> setAppLock(bool on) => set(SettingKeys.appLock, '$on');

  Future<void> setLastBackupAt(DateTime at) =>
      set(SettingKeys.lastBackupAt, at.toIso8601String());

  static Map<String, String> _toMap(List<SettingRow> rows) => {
    for (final r in rows) r.key: r.value,
  };
}
