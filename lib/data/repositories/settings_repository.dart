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

  /// "auto" (CBU rate) or "manual" (the rate the user typed).
  static const usdRateMode = 'usd_rate_mode';
  static const usdManualRate = 'usd_manual_rate';

  /// When the CBU rate was last fetched (ISO 8601).
  static const usdRateFetchedAt = 'usd_rate_fetched_at';
  static const showUsdOnHome = 'show_usd_on_home';
  static const showUsdInList = 'show_usd_in_list';
  static const roundDollars = 'round_dollars';

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

  /// True when the user typed their own USD rate instead of using CBU.
  bool get usdRateManual => _values[SettingKeys.usdRateMode] == 'manual';

  /// The rate the user typed, in UZS for 1 USD. Null when never set.
  double? get usdManualRate {
    final rate = double.tryParse(_values[SettingKeys.usdManualRate] ?? '');
    return rate != null && rate > 0 ? rate : null;
  }

  DateTime? get usdRateFetchedAt =>
      DateTime.tryParse(_values[SettingKeys.usdRateFetchedAt] ?? '');

  /// Balance, income and expenses on Home show "≈ $". On by default.
  bool get showUsdOnHome => _values[SettingKeys.showUsdOnHome] != 'false';

  /// The transaction list shows "≈ $" under each amount. Off by default.
  bool get showUsdInList => _values[SettingKeys.showUsdInList] == 'true';

  /// "≈ $1 484" instead of "≈ $1 484.19". On by default.
  bool get roundDollars => _values[SettingKeys.roundDollars] != 'false';

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

  Future<void> setUsdRateManual(bool manual) =>
      set(SettingKeys.usdRateMode, manual ? 'manual' : 'auto');

  Future<void> setUsdManualRate(double rate) =>
      set(SettingKeys.usdManualRate, '$rate');

  Future<void> setUsdRateFetchedAt(DateTime at) =>
      set(SettingKeys.usdRateFetchedAt, at.toIso8601String());

  Future<void> setShowUsdOnHome(bool on) =>
      set(SettingKeys.showUsdOnHome, '$on');

  Future<void> setShowUsdInList(bool on) =>
      set(SettingKeys.showUsdInList, '$on');

  Future<void> setRoundDollars(bool on) => set(SettingKeys.roundDollars, '$on');

  Future<void> setLastBackupAt(DateTime at) =>
      set(SettingKeys.lastBackupAt, at.toIso8601String());

  static Map<String, String> _toMap(List<SettingRow> rows) => {
    for (final r in rows) r.key: r.value,
  };
}
