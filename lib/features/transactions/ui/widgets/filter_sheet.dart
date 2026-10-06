import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/transaction_kind.dart';
import '../../../../data/providers/data_providers.dart';
import '../../domain/transaction_filter.dart';
import '../../providers/transactions_providers.dart';

/// Opens the "Filters" sheet. Changes apply when the user taps
/// "Show N results".
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.background,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _FilterSheet(),
  );
}

/// Quick date choices in the sheet.
enum _DatePreset { thisMonth, lastMonth, threeMonths, custom }

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  /// The filters being edited. The search text is kept as it is.
  late TransactionFilter _draft = ref.read(transactionFilterProvider);

  DateTime get _now => ref.read(clockProvider).now();

  DateRange _presetRange(_DatePreset p) {
    final now = _now;
    return switch (p) {
      _DatePreset.thisMonth => DateRange.month(now),
      _DatePreset.lastMonth => DateRange.month(
        shiftMonths(monthStart(now), -1),
      ),
      _DatePreset.threeMonths => DateRange(
        shiftMonths(monthStart(now), -2),
        nextMonthStart(now),
      ),
      _DatePreset.custom => _draft.period ?? DateRange.month(now),
    };
  }

  _DatePreset? get _selectedPreset {
    final period = _draft.period;
    if (period == null) return null;
    for (final p in _DatePreset.values.take(3)) {
      if (_presetRange(p) == period) return p;
    }
    return _DatePreset.custom;
  }

  void _update(TransactionFilter f) => setState(() => _draft = f);

  Future<void> _pickDate({required bool from}) async {
    final now = _now;
    final current = _draft.period ?? DateRange.month(now);
    // The range end is exclusive; the field shows the day before it.
    final shownTo = current.to.subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? current.from : shownTo,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    var start = from ? picked : current.from;
    var end = from ? shownTo : picked;
    if (end.isBefore(start)) (start, end) = (end, start);
    _update(
      _draft.copyWith(
        period: () => DateRange(
          DateTime(start.year, start.month, start.day),
          DateTime(end.year, end.month, end.day + 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kinds = switch (_draft.type) {
      TypeFilter.expenses => [TransactionKind.expense],
      TypeFilter.income => [TransactionKind.income],
      TypeFilter.all => TransactionKind.values,
    };
    final categories = <CategoryRow>[
      for (final k in kinds) ...?ref.watch(categoriesProvider(k)).value,
    ];
    final expenseNames = {
      for (final c in categories)
        if (c.kind == TransactionKind.expense) c.name,
    };
    // Live count for the button, using the edited filters.
    final count = ref
        .watch(periodTransactionsProvider(_draft.period ?? allTimeRange))
        .whenData((items) => TransactionListView.build(items, _draft))
        .value
        ?.items
        .length;
    final period = _draft.period;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: AppText.title20.copyWith(letterSpacing: 0),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _update(
                      TransactionFilter(
                        period: DateRange.month(_now),
                        query: _draft.query,
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: AppText.body15.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Type'),
                    SegmentedTabs(
                      options: [
                        for (final t in TypeFilter.values)
                          SegmentOption(t, t.label),
                      ],
                      selected: _draft.type,
                      onChanged: (t) => _update(
                        // Categories of the other kind no longer apply.
                        _draft.copyWith(type: t, categoryIds: const {}),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Label('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in categories)
                          CategoryChip(
                            category: cat,
                            // "Other" exists for both kinds; say which.
                            label:
                                cat.kind == TransactionKind.income &&
                                    expenseNames.contains(cat.name)
                                ? '${cat.name} · income'
                                : null,
                            selected: _draft.categoryIds.contains(cat.id),
                            onTap: () {
                              final ids = {..._draft.categoryIds};
                              if (!ids.remove(cat.id)) ids.add(cat.id);
                              _update(_draft.copyWith(categoryIds: ids));
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('Date range'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (p, label) in const [
                          (_DatePreset.thisMonth, 'This month'),
                          (_DatePreset.lastMonth, 'Last month'),
                          (_DatePreset.threeMonths, '3 months'),
                          (_DatePreset.custom, 'Custom'),
                        ])
                          AppChip(
                            label: label,
                            selected: _selectedPreset == p,
                            onTap: () => p == _DatePreset.custom
                                ? _pickDate(from: true)
                                : _update(
                                    _draft.copyWith(
                                      period: () => _presetRange(p),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'From',
                            value: period == null
                                ? 'Any'
                                : DateText.fullDate(period.from),
                            onTap: () => _pickDate(from: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'To',
                            value: period == null
                                ? 'Any'
                                : DateText.fullDate(
                                    period.to.subtract(const Duration(days: 1)),
                                  ),
                            onTap: () => _pickDate(from: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('Sort by'),
                    for (final s in SortOrder.values)
                      _RadioRow(
                        label: s.label,
                        selected: _draft.sort == s,
                        onTap: () => _update(_draft.copyWith(sort: s)),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: count == null
                    ? 'Show results'
                    : 'Show $count ${count == 1 ? 'result' : 'results'}',
                onPressed: () {
                  ref.read(transactionFilterProvider.notifier).apply(_draft);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline13.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

/// "From" / "To" box that opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: c.divider),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.small12Regular.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 6),
        Semantics(
          container: true,
          button: true,
          label: '$label date, $value',
          excludeSemantics: true,
          child: Material(
            color: c.surface,
            shape: shape,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppText.body15Regular),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sort option with a round radio mark on the right.
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? AppText.body15Strong
                      : AppText.body15Regular,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.primary : c.divider,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
