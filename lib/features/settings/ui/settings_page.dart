import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/page_title.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../router.dart';
import '../../../shell/placeholder_body.dart';

/// Settings tab. Only "Appearance" works for now; the rest is Task 15.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            const PageTitle('Settings'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GroupLabel('Appearance'),
                  SegmentedTabs(
                    height: 40,
                    options: const [
                      SegmentOption(ThemeMode.light, 'Light'),
                      SegmentOption(ThemeMode.dark, 'Dark'),
                      SegmentOption(ThemeMode.system, 'System'),
                    ],
                    selected: ref.watch(themeModeProvider),
                    onChanged: ref.read(themeModeProvider.notifier).set,
                  ),
                  const SizedBox(height: 24),
                  const _GroupLabel('Developer'),
                  AppCard(
                    onTap: () => context.push(Routes.designPreview),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Design preview', style: AppText.body15),
                        ),
                        AppIcon(
                          AppIcons.chevronRight,
                          size: 18,
                          color: c.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const PlaceholderCard(
                    message: 'The full Settings screen is built in Task 15.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small upper-case label above a settings group, like "APPEARANCE".
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline13.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}
