import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/pill.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import 'delete_confirm_sheet.dart';

/// Full details of one transaction, with Edit, Duplicate and Delete.
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(transactionProvider(id));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onEdit: item.value == null
                  ? null
                  : () => context.push(Routes.editTransaction(id)),
              onDelete: item.value == null
                  ? null
                  : () => _delete(context, ref, item.value!),
            ),
            Expanded(
              child: switch (item) {
                AsyncData(value: final t?) => _Body(
                  item: t,
                  onEdit: () => context.push(Routes.editTransaction(id)),
                  onDuplicate: () => _duplicate(context, ref),
                  onDelete: () => _delete(context, ref, t),
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

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final newId = await ref.read(transactionRepositoryProvider).duplicate(id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Copy added with today’s date'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => router.push(Routes.transactionDetail(newId)),
          ),
        ),
      );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionDetails item,
  ) async {
    final confirmed = await showDeleteConfirmSheet(context, item);
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    // Leave the page first, so it does not flash "not found".
    context.pop();
    await repo.delete(item.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore(item.transaction),
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
                  'Transaction',
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
                    semanticLabel: 'Edit transaction',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton.raised(
                    icon: AppIcons.trash,
                    color: context.colors.expense,
                    semanticLabel: 'Delete transaction',
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
    required this.onDuplicate,
    required this.onDelete,
  });

  final TransactionDetails item;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = item.transaction;
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
                icon: item.paymentMethod.icon,
                label: 'Payment',
                value: item.paymentMethod.name,
                divider: true,
              ),
              if (row.note != null)
                _InfoRow(
                  icon: AppIcons.pencil,
                  label: 'Note',
                  value: row.note!,
                  divider: true,
                ),
              if (row.description != null)
                _InfoRow(
                  icon: AppIcons.list,
                  label: 'Description',
                  value: row.description!,
                  divider: true,
                ),
            ],
          ),
        ),
        if (row.receiptPath != null) ...[
          const SizedBox(height: 16),
          _ReceiptCard(path: row.receiptPath!),
        ],
        const SizedBox(height: 16),
        _CategoryInsight(item: item),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Edit',
                icon: AppIcons.pencil,
                onPressed: onEdit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SecondaryButton(
                label: 'Duplicate',
                icon: AppIcons.copy,
                onPressed: onDuplicate,
              ),
            ),
          ],
        ),
        TextActionButton(
          label: 'Delete transaction',
          icon: AppIcons.trash,
          color: c.expense,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// Big icon, category name, amount and the Expense / Income label.
class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final TransactionDetails item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIncome = item.kind == TransactionKind.income;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        children: [
          CategoryIconTile(
            icon: item.category.icon,
            color: item.category.color,
            size: 64,
            iconSize: 30,
            radius: 20,
          ),
          const SizedBox(height: 10),
          Text(
            item.category.name,
            style: AppText.body15.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          AmountText(
            item.signedAmount,
            signed: true,
            color: isIncome ? c.income : c.textPrimary,
            style: AppText.amount40.copyWith(fontSize: 38),
            unitStyle: AppText.body17.copyWith(color: c.textTertiary),
            unitGap: 6,
          ),
          const SizedBox(height: 10),
          Pill(
            isIncome ? 'Income' : 'Expense',
            foreground: isIncome ? c.income : c.expense,
            background: isIncome ? c.incomeSoft : c.expenseSoft,
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
            // Labels take only the width they need; values are
            // right-aligned, so long values like the date fit on one line.
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

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECEIPT',
            style: AppText.overline13.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.divider),
                ),
                child: AppIcon(
                  AppIcons.receipt,
                  size: 24,
                  strokeWidth: 1.5,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  path.split('/').last,
                  style: AppText.body15,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Groceries in September: 820 000 UZS across 6 transactions — 27% of
/// your spending."
class _CategoryInsight extends ConsumerWidget {
  const _CategoryInsight({required this.item});

  final TransactionDetails item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final month = ref.watch(monthTransactionsProvider(item.occurredAt)).value;
    if (month == null) return const SizedBox.shrink();

    final sameKind = month.where((t) => t.kind == item.kind);
    final kindTotal = sameKind.fold(0, (s, t) => s + t.transaction.amount);
    final inCategory = sameKind.where((t) => t.category.id == item.category.id);
    final total = inCategory.fold(0, (s, t) => s + t.transaction.amount);
    final count = inCategory.length;
    final percent = kindTotal == 0 ? 0 : (total / kindTotal * 100).round();
    final what = item.kind == TransactionKind.income ? 'income' : 'spending';

    return AppCard(
      child: Row(
        children: [
          AppIcon(AppIcons.chart, color: c.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${item.category.name} in '
                        '${DateText.month(item.occurredAt)}: ',
                  ),
                  TextSpan(
                    text: MoneyFormat.withCurrency(total),
                    style: AppText.label14Strong.copyWith(color: c.textPrimary),
                  ),
                  TextSpan(
                    text:
                        ' across $count '
                        '${count == 1 ? 'transaction' : 'transactions'} '
                        '— $percent% of your $what.',
                  ),
                ],
              ),
              style: AppText.label14Regular.copyWith(
                color: c.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
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
          'This transaction no longer exists.',
          textAlign: TextAlign.center,
          style: AppText.body15.copyWith(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
