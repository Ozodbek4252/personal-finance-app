import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/pill.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../transactions/ui/widgets/exchange_tile.dart';

/// Full details of one exchange, with Edit and Delete.
class ExchangeDetailPage extends ConsumerWidget {
  const ExchangeDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(exchangeProvider(id));
    final loaded = item.value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onEdit: loaded == null
                  ? null
                  : () => context.push(Routes.editExchange(id)),
              onDelete: loaded == null
                  ? null
                  : () => _delete(context, ref, loaded),
            ),
            Expanded(
              child: switch (item) {
                AsyncData(value: final e?) => _Body(
                  item: e,
                  onEdit: () => context.push(Routes.editExchange(id)),
                  onDelete: () => _delete(context, ref, e),
                ),
                AsyncData() => const _Missing(),
                AsyncError(:final error) => Center(child: Text('$error')),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ExchangeDetails item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this exchange?'),
        content: Text(
          'The money goes back: ${ExchangeTile.gaveText(item).substring(1)} '
          'to ${item.from.name}, and '
          '${ExchangeTile.gotText(item, signed: false)} leaves '
          '${item.to.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(exchangeRepositoryProvider);
    // Leave the page first, so it does not flash "not found".
    context.pop();
    await repo.delete(item.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Exchange deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore(item.exchange),
          ),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton.raised(
                  icon: AppIcons.chevronLeft,
                  semanticLabel: 'Back',
                  onTap: onBack,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Exchange',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleIconButton.raised(
                    icon: AppIcons.pencil,
                    semanticLabel: 'Edit exchange',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton.raised(
                    icon: AppIcons.trash,
                    color: context.colors.expense,
                    semanticLabel: 'Delete exchange',
                    onTap: onDelete,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ExchangeDetails item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = item.exchange;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _Hero(item: item),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            children: [
              _InfoRow(
                icon: AppIcons.calendar,
                label: 'Date',
                value: DateText.detail(item.occurredAt),
              ),
              _InfoRow(
                icon: item.from.icon,
                label: 'From',
                value: item.from.name,
                divider: true,
              ),
              _InfoRow(
                icon: item.to.icon,
                label: 'To',
                value: item.to.name,
                divider: true,
              ),
              _InfoRow(
                icon: AppIcons.exchange,
                label: 'Rate',
                value: '1 USD = ${MoneyFormat.rate(row.rate)} UZS',
                divider: true,
              ),
              if (row.fee > 0)
                _InfoRow(
                  icon: AppIcons.plus,
                  label: 'Fee',
                  value: ExchangeTile.amountText(item.fromCurrency, row.fee),
                  divider: true,
                ),
              if (row.note != null)
                _InfoRow(
                  icon: AppIcons.pencil,
                  label: 'Note',
                  value: row.note!,
                  divider: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.info, color: c.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Exchanges move money between your so’m and dollar '
                  'balances. They don’t count as income or expenses.',
                  style: AppText.label14Regular.copyWith(
                    color: c.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Edit',
          icon: AppIcons.pencil,
          onPressed: onEdit,
        ),
        TextActionButton(
          label: 'Delete exchange',
          icon: AppIcons.trash,
          color: c.expense,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// Exchange icon, "UZS → USD", what came in and what went out.
class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final ExchangeDetails item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppIcon(AppIcons.exchange, size: 30, color: c.accent),
          ),
          const SizedBox(height: 10),
          Text(
            '${item.fromCurrency.code} → ${item.toCurrency.code}',
            style: AppText.body15.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ExchangeTile.gotText(item),
              maxLines: 1,
              style: AppText.amount40.copyWith(fontSize: 38, color: c.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ExchangeTile.gaveText(item),
            style: AppText.body17.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: 10),
          Pill(
            'Exchange',
            foreground: c.accent,
            background: c.accentSoft,
            strong: true,
          ),
        ],
      ),
    );
  }
}

/// One "label .... value" row with an icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.divider = false,
  });

  final AppIconData icon;
  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: divider ? Border(top: BorderSide(color: c.divider)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, color: c.textTertiary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppText.label14Regular.copyWith(color: c.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AppText.body15.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'This exchange no longer exists.',
          textAlign: TextAlign.center,
          style: AppText.body15.copyWith(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
