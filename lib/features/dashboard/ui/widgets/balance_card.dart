import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../data/providers/data_providers.dart';
import '../../providers/dashboard_providers.dart';

/// "Current balance" with a hide button and one chip per payment method.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  /// The design shows the three biggest methods.
  static const _maxChips = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final summary = ref.watch(balanceSummaryProvider).value;
    final hidden = summary?.hidden ?? false;

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current balance',
                  style: AppText.label14.copyWith(color: c.textSecondary),
                ),
              ),
              Transform.translate(
                offset: const Offset(10, 0),
                child: CircleIconButton(
                  icon: hidden ? AppIcons.eyeOff : AppIcons.eye,
                  iconSize: 18,
                  color: c.textTertiary,
                  semanticLabel: hidden ? 'Show balance' : 'Hide balance',
                  onTap: () => ref
                      .read(settingsRepositoryProvider)
                      .setBalanceHidden(!hidden),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AmountText(
            summary?.total ?? 0,
            hidden: hidden,
            style: AppText.amount40,
            unitStyle: AppText.body17,
            unitGap: 8,
          ),
          if (summary != null && summary.methods.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in summary.methods.take(_maxChips))
                  Pill(
                    '${m.method.name} '
                    '${hidden ? '••••' : MoneyFormat.amount(m.balance)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
