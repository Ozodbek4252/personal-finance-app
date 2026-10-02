import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon.dart';

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
