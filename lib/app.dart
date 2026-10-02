import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'dev/design_preview_page.dart';

class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Personal Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Temporary home page to check the design tokens.
      // It is replaced by the real app shell in Task 3.
      home: const DesignPreviewPage(),
    );
  }
}
