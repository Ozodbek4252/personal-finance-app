import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon.dart';
import '../core/widgets/buttons.dart';

/// Temporary card for screens that are not built yet.
/// Each one is replaced in a later task.
class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AppIcon(AppIcons.info, color: c.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppText.label14.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary full page with a back button, for routes that are linked
/// already but built in a later task.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: AppIcons.chevronLeft,
                  semanticLabel: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppText.heading17,
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: PlaceholderCard(message: message),
            ),
          ],
        ),
      ),
    );
  }
}
