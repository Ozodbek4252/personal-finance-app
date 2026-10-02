import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the Onest font from the assets folder into the test engine.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File('assets/fonts/Onest-Variable.ttf').readAsBytesSync();
  final loader = FontLoader('Onest')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
