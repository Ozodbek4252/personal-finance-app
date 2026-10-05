import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';

/// Floating card that asks "Delete this transaction?".
/// Returns true when the user taps Delete.
Future<bool?> showDeleteConfirmSheet(
  BuildContext context,
  TransactionDetails item,
) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    // Taller than the default half screen, for small phones and big text.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    elevation: 0,
    builder: (context) => _DeleteConfirm(item: item),
  );
}

class _DeleteConfirm extends ConsumerWidget {
  const _DeleteConfirm({required this.item});

  final TransactionDetails item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final note = item.transaction.note;
    final when = DateText.relativeDayTime(item.occurredAt, now: now);
    final isIncome = item.kind == TransactionKind.income;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 20),
                blurRadius: 50,
              ),
            ],
          ),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'Delete this transaction?',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.expenseSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AppIcon(AppIcons.trash, size: 24, color: c.expense),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete this transaction?',
                  style: AppText.title20.copyWith(letterSpacing: 0),
                ),
                const SizedBox(height: 6),
                Text(
                  'It will be removed from your history, balance and '
                  'statistics. This can’t be undone.',
                  style: AppText.body15Regular.copyWith(
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CategoryIconTile(
                        icon: item.category.icon,
                        color: item.category.color,
                        size: 40,
                        iconSize: 20,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category.name,
                              style: AppText.body15Strong,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              note == null ? when : '$note · $when',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption13Regular.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AmountText(
                        item.signedAmount,
                        signed: true,
                        color: isIncome ? c.income : c.textPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _BigButton(
                  label: 'Delete',
                  background: c.expense,
                  foreground: Colors.white,
                  onTap: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 8),
                _BigButton(
                  label: 'Cancel',
                  background: c.surfaceMuted,
                  foreground: c.textPrimary,
                  onTap: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 54 px full-width button of the confirm card.
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                label,
                style: AppText.body16Strong.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
