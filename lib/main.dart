import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/bootstrap.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app is designed for portrait phones only.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final overrides = await bootstrap(AppDatabase.onDevice());
  runApp(
    ProviderScope(overrides: overrides, child: const PersonalFinanceApp()),
  );
}
