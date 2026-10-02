import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../data/providers/data_providers.dart';
import '../../../../router.dart';
import '../../providers/dashboard_providers.dart';

/// Today's date, the month picker button and the search button.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(clockProvider).now();
    final month = ref.watch(selectedMonthProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateText.weekdayDayMonth(today),
                  style: AppText.caption13Regular.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  container: true,
                  button: true,
                  label: 'Change month, ${DateText.monthYear(month)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => showMonthPicker(context),
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateText.monthYear(month),
                            style: AppText.title22,
                          ),
                          const SizedBox(width: 4),
                          AppIcon(
                            AppIcons.chevronDown,
                            size: 18,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircleIconButton.raised(
            icon: AppIcons.search,
            semanticLabel: 'Search transactions',
            onTap: () => context.go(Routes.transactions),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with the months that can be shown, newest first.
Future<void> showMonthPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => const _MonthPickerSheet(),
  );
}

class _MonthPickerSheet extends ConsumerWidget {
  const _MonthPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final months = ref.watch(selectableMonthsProvider);
    final selected = ref.watch(selectedMonthProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Choose month', style: AppText.heading17),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  for (final m in months)
                    ListTile(
                      minTileHeight: 52,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(
                        DateText.monthYear(m),
                        style: m == selected
                            ? AppText.body15Strong
                            : AppText.body15,
                      ),
                      trailing: m == selected
                          ? AppIcon(AppIcons.check, color: c.textPrimary)
                          : null,
                      selected: m == selected,
                      onTap: () {
                        ref.read(selectedMonthProvider.notifier).select(m);
                        Navigator.pop(context);
                      },
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
