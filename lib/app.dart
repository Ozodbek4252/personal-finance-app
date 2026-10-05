import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/format/money_format.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/time/clock.dart';
import 'data/providers/data_providers.dart';
import 'features/app_lock/app_lock.dart';
import 'router.dart';

class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global formats from Settings. See applyNumberStyle and
    // applyMonthStartDay for how a change reaches every screen.
    final settings = ref.watch(currentSettingsProvider);
    MoneyFormat.style = settings.numberStyle;
    MonthCycle.startDay = settings.monthStartDay;

    return MaterialApp.router(
      title: 'Personal Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Status bar icons follow the theme.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: AppLockGate(child: child!),
        );
      },
    );
  }
}
