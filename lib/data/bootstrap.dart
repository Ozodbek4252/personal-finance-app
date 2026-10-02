import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/time/clock.dart';
import 'db/app_database.dart';
import 'db/seed.dart';
import 'providers/data_providers.dart';
import 'repositories/settings_repository.dart';

/// Debug builds start with the design's sample data, and "today" is
/// pinned to 30 September 2026 so screens match the design.
///
/// Turn it off with `flutter run --dart-define=SAMPLE_DATA=false`.
const useSampleData = bool.fromEnvironment(
  'SAMPLE_DATA',
  defaultValue: kDebugMode,
);

/// Opens the database, adds defaults (and sample data in debug), and
/// returns the provider overrides the app needs.
Future<List<Override>> bootstrap(
  AppDatabase db, {
  bool sampleData = useSampleData,
}) async {
  await ensureDefaults(db);
  if (sampleData) await seedSampleData(db);

  final settings = await SettingsRepository(db).load();
  return [
    databaseProvider.overrideWithValue(db),
    initialSettingsProvider.overrideWithValue(settings),
    if (sampleData) clockProvider.overrideWithValue(ShiftedClock(sampleToday)),
  ];
}
