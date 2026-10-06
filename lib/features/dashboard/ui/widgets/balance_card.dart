import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../data/providers/data_providers.dart';
import '../../providers/dashboard_providers.dart';

/// "Current balance" with a hide button and one chip per payment method.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  /// The design shows the three biggest methods.
  static const _maxChips = 3;

  /// White text on the indigo card, at the design's opacities.
  static const _soft = Color(0xD1FFFFFF); // 82%
  static const _unit = Color(0xBFFFFFFF); // 75%
  static const _chip = Color(0x29FFFFFF); // 16%

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final summary = ref.watch(balanceSummaryProvider).value;
    final hidden = summary?.hidden ?? false;

    // A filled indigo card, so the balance stands out from the others.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.hero,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current balance',
                  style: AppText.label14.copyWith(color: _soft),
                ),
              ),
              Transform.translate(
                offset: const Offset(10, 0),
                child: CircleIconButton(
                  icon: hidden ? AppIcons.eyeOff : AppIcons.eye,
                  iconSize: 18,
                  color: _soft,
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
            color: Colors.white,
            style: AppText.amount40,
            unitStyle: AppText.body17.copyWith(color: _unit),
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
                    background: _chip,
                    foreground: Colors.white,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
