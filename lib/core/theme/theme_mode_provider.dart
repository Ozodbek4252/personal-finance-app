import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/data_providers.dart';

/// Light, dark or system theme, saved in the settings table.
/// Settings > Appearance changes it.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(currentSettingsProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode; // Update the UI right away.
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}
