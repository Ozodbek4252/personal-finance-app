import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../router.dart';

/// Shown on a fresh install, before the first transaction.
class EmptyDashboardCard extends StatelessWidget {
  const EmptyDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AppIcon(
                    AppIcons.inbox,
                    size: 32,
                    strokeWidth: 1.6,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No transactions yet',
                  textAlign: TextAlign.center,
                  style: AppText.title20.copyWith(
                    fontSize: 19,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Text(
                    'Record your first expense or income. Your balance, '
                    'savings and statistics will fill in from there.',
                    textAlign: TextAlign.center,
                    style: AppText.body15Regular.copyWith(
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Add first transaction',
            icon: AppIcons.plus,
            onPressed: () => context.push(Routes.addExpense),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Tip: use the '),
                TextSpan(
                  text: '000',
                  style: AppText.caption13Strong.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const TextSpan(text: ' key to type large amounts faster'),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppText.caption13Regular.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
