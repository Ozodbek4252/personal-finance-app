import 'dart:async';

import 'helpers/load_fonts.dart';

/// Runs before every test file. Loads the real app font so text has
/// real widths and overflow checks mean something.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
