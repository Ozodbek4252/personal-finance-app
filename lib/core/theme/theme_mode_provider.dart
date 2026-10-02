import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/data_providers.dart';
import '../../data/repositories/settings_repository.dart';

/// Light, dark or system theme, saved in the settings table.
/// Settings > Appearance changes it.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Until the live settings load, use the ones read at startup.
    final live = ref.watch(settingsProvider);
    final AppSettings settings = live.hasValue
        ? live.requireValue
        : ref.watch(initialSettingsProvider);
    return settings.themeMode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode; // Update the UI right away.
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}
