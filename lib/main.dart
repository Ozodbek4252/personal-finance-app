import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/bootstrap.dart';
import 'data/db/app_database.dart';
import 'data/providers/data_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app is designed for portrait phones only.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final overrides = await bootstrap(AppDatabase.onDevice());
  final container = ProviderContainer(overrides: overrides);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PersonalFinanceApp(),
    ),
  );

  // Get today's USD rate in the background, now and each time the app
  // comes back to the front. Without internet the last saved rate stays.
  final rates = container.read(rateServiceProvider);
  unawaited(rates.refreshIfStale());
  AppLifecycleListener(onResume: () => unawaited(rates.refreshIfStale()));
}
