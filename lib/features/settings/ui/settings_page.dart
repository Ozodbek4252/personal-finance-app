import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/page_title.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/backup/file_io.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../app_lock/app_lock.dart';
import '../../transactions/providers/transactions_providers.dart';
import '../domain/csv_export.dart';
import '../domain/settings_actions.dart';

/// Settings tab: profile, general options, appearance, links to manage
/// categories and payment methods, and security and data tools.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final methods = ref.watch(paymentMethodsProvider).value ?? const [];
    final categoryCount = [
      for (final k in TransactionKind.values)
        ...?ref.watch(categoriesProvider(k)).value,
    ].length;
    final defaultMethod = methods
        .where((m) => m.id == settings.defaultPaymentMethodId)
        .firstOrNull;
    final lastBackup = settings.lastBackupAt;
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 28 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const PageTitle('Settings'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(onEditName: () => _editName(context, ref)),
                  const SizedBox(height: 16),
                  const _GroupLabel('General'),
                  _RowsCard(
                    rows: [
                      _SettingRow(
                        icon: AppIcons.coins,
                        label: 'Primary currency',
                        value: 'UZS · so’m',
                        onTap: () => _showCurrency(context),
                      ),
                      _SettingRow(
                        icon: AppIcons.hash,
                        label: 'Number format',
                        value: settings.numberStyle.example,
                        onTap: () => _pickNumberStyle(context, ref),
                      ),
                      _SettingRow(
                        icon: AppIcons.calendar,
                        label: 'Month starts on',
                        value: ordinal(settings.monthStartDay),
                        onTap: () => _pickMonthStart(context, ref),
                      ),
                      _SettingRow(
                        icon: AppIcons.card,
                        label: 'Default payment',
                        value: defaultMethod?.name ?? 'Not set',
                        onTap: () => context.push(Routes.paymentMethods),
                      ),
                      _SettingRow(
                        icon: AppIcons.globe,
                        label: 'Language',
                        value: 'English',
                        onTap: () => _showLanguage(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel('Appearance'),
                  SegmentedTabs(
                    height: 40,
                    options: const [
                      SegmentOption(ThemeMode.light, 'Light'),
                      SegmentOption(ThemeMode.dark, 'Dark'),
                      SegmentOption(ThemeMode.system, 'System'),
                    ],
                    selected: ref.watch(themeModeProvider),
                    onChanged: ref.read(themeModeProvider.notifier).set,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel('Manage'),
                  _RowsCard(
                    rows: [
                      _SettingRow(
                        icon: AppIcons.list,
                        label: 'Categories',
                        value: '$categoryCount',
                        onTap: () => context.push(Routes.categories),
                      ),
                      _SettingRow(
                        icon: AppIcons.card,
                        label: 'Payment methods',
                        value: '${methods.length}',
                        onTap: () => context.push(Routes.paymentMethods),
                      ),
                      _SettingRow(
                        icon: AppIcons.coins,
                        label: 'Currencies',
                        value: '1 active',
                        onTap: () => _showCurrency(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel('Security & data'),
                  _RowsCard(
                    rows: [
                      _SettingRow(
                        icon: AppIcons.lock,
                        label: 'App lock',
                        trailing: Switch(
                          value: settings.appLock,
                          activeTrackColor: context.colors.primary,
                          activeThumbColor: Colors.white,
                          onChanged: (on) => _setAppLock(context, ref, on),
                        ),
                        onTap: () =>
                            _setAppLock(context, ref, !settings.appLock),
                      ),
                      _SettingRow(
                        icon: AppIcons.download,
                        label: 'Export to CSV',
                        onTap: () => _exportCsv(context, ref),
                      ),
                      _SettingRow(
                        icon: AppIcons.cloud,
                        label: 'Backup & restore',
                        value: lastBackup == null
                            ? 'Never'
                            : 'Last: ${DateText.shortDay(lastBackup, now: now).toLowerCase()}',
                        onTap: () => _backupMenu(context, ref),
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    const _GroupLabel('Developer'),
                    _RowsCard(
                      rows: [
                        _SettingRow(
                          icon: AppIcons.settings,
                          label: 'Design preview',
                          onTap: () => context.push(Routes.designPreview),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    textAlign: TextAlign.center,
                    style: AppText.small12Regular.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Actions ----

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final name = await showTextInputDialog(
      context,
      title: 'Your name',
      initial: ref.read(currentSettingsProvider).userName ?? '',
      validate: (t) => t.trim().isEmpty ? 'Enter a name' : null,
    );
    if (name != null) {
      await ref.read(settingsRepositoryProvider).setUserName(name);
    }
  }

  Future<void> _showCurrency(BuildContext context) => showOptionSheet<String>(
    context,
    title: 'Currency',
    selected: 'UZS',
    options: const [
      SheetOption(
        value: 'UZS',
        label: 'UZS · Uzbek so’m',
        subtitle: 'Other currencies are not supported yet',
      ),
    ],
  );

  Future<void> _showLanguage(BuildContext context) => showOptionSheet<String>(
    context,
    title: 'Language',
    selected: 'en',
    options: const [
      SheetOption(
        value: 'en',
        label: 'English',
        subtitle: 'More languages are coming later',
      ),
    ],
  );

  Future<void> _pickNumberStyle(BuildContext context, WidgetRef ref) async {
    final picked = await showOptionSheet<NumberStyle>(
      context,
      title: 'Number format',
      selected: ref.read(currentSettingsProvider).numberStyle,
      options: [
        for (final s in NumberStyle.values)
          SheetOption(value: s, label: s.example),
      ],
    );
    if (picked != null) await applyNumberStyle(ref, picked);
  }

  Future<void> _pickMonthStart(BuildContext context, WidgetRef ref) async {
    final picked = await showOptionSheet<int>(
      context,
      title: 'Month starts on',
      selected: ref.read(currentSettingsProvider).monthStartDay,
      options: [
        for (var d = 1; d <= 28; d++)
          SheetOption(
            value: d,
            label: ordinal(d),
            subtitle: d == 1 ? 'Calendar months' : null,
          ),
      ],
    );
    if (picked != null) await applyMonthStartDay(ref, picked);
  }

  Future<void> _setAppLock(BuildContext context, WidgetRef ref, bool on) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (!on) {
      await repo.setAppLock(false);
      return;
    }
    final auth = ref.read(authenticatorProvider);
    if (!await auth.isAvailable()) {
      if (context.mounted) {
        _toast(context, 'Set up a screen lock on your phone first.');
      }
      return;
    }
    // Check once that it works before turning it on.
    if (await auth.authenticate('Turn on App lock')) {
      await repo.setAppLock(true);
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final items = await ref
        .read(transactionRepositoryProvider)
        .getBetween(allTimeRange.from, allTimeRange.to);
    final exchanges = await ref.read(exchangeRepositoryProvider).getAll();
    if (!context.mounted) return;
    if (items.isEmpty && exchanges.isEmpty) {
      _toast(context, 'There are no transactions to export yet.');
      return;
    }
    final today = DateFormat(
      'yyyy-MM-dd',
    ).format(ref.read(clockProvider).now());
    await ref.read(shareTextFileProvider)(
      fileName: 'personal_finance_transactions_$today.csv',
      content: buildTransactionsCsv(items, exchanges: exchanges),
      mimeType: 'text/csv',
    );
  }

  Future<void> _backupMenu(BuildContext context, WidgetRef ref) async {
    final action = await showOptionSheet<String>(
      context,
      title: 'Backup & restore',
      options: const [
        SheetOption(
          value: 'backup',
          label: 'Create backup',
          subtitle: 'Saves all data to a file you can keep or send',
          leading: AppIcon(AppIcons.download, size: 20),
        ),
        SheetOption(
          value: 'restore',
          label: 'Restore from file',
          subtitle: 'Replaces all data with a backup file',
          leading: AppIcon(AppIcons.cloud, size: 20),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case 'backup':
        await _createBackup(context, ref);
      case 'restore':
        await _restore(context, ref);
    }
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider).now();
    final text = await BackupService(ref.read(databaseProvider)).create();
    await ref.read(shareTextFileProvider)(
      fileName:
          'personal_finance_backup_${DateFormat('yyyy-MM-dd').format(now)}.json',
      content: text,
      mimeType: 'application/json',
    );
    await ref.read(settingsRepositoryProvider).setLastBackupAt(now);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final text = await ref.read(pickBackupTextProvider)();
    if (text == null || !context.mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'Your current transactions, categories, payment methods and '
          'settings will be replaced by the backup. Receipt photos are not '
          'part of a backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Replace',
              style: TextStyle(color: context.colors.expense),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    try {
      await BackupService(ref.read(databaseProvider)).restore(text);
      final restored = await ref.read(settingsRepositoryProvider).load();
      // Formats may differ in the backup.
      MoneyFormat.style = restored.numberStyle;
      await applyMonthStartDay(ref, restored.monthStartDay);
      if (context.mounted) _toast(context, 'Backup restored');
    } on BackupFormatException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }
}

/// "1st", "2nd", "3rd", "4th", "11th", "21st".
String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// Initial, name and "Tracking since April 2026 · 214 transactions".
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.onEditName});

  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final name = ref.watch(currentSettingsProvider).userName;
    final months = ref.watch(monthTotalsProvider).value ?? const [];
    final count = ref.watch(transactionCountProvider).value ?? 0;
    final since = months.isEmpty
        ? 'No transactions yet'
        : 'Tracking since ${DateText.monthYear(months.first.month)} · '
              '$count ${count == 1 ? 'transaction' : 'transactions'}';
    final shown = (name == null || name.isEmpty) ? 'Add your name' : name;

    return AppCard(
      onTap: onEditName,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Text(
              (name == null || name.isEmpty)
                  ? '?'
                  : name.characters.first.toUpperCase(),
              style: AppText.title20.copyWith(color: c.onPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shown, style: AppText.heading17),
                const SizedBox(height: 2),
                Text(
                  since,
                  style: AppText.caption13Regular.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppText.overline13.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// White card with setting rows and thin lines between them.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows});

  final List<_SettingRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i > 0
                    ? Border(top: BorderSide(color: c.divider))
                    : null,
              ),
              child: row,
            ),
        ],
      ),
    );
  }
}

/// Icon, label, value (or a custom [trailing]) and a chevron.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
  });

  final AppIconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(icon, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppText.body15)),
                if (trailing != null)
                  trailing!
                else ...[
                  if (value != null)
                    Text(
                      value!,
                      style: AppText.label14Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 8),
                  AppIcon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: c.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
