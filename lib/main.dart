import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/bootstrap.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final overrides = await bootstrap(AppDatabase.onDevice());
  runApp(
    ProviderScope(overrides: overrides, child: const PersonalFinanceApp()),
  );
}
