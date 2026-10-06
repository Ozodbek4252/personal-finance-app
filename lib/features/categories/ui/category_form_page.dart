import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import 'categories_page.dart';

/// "New category" form, or "Edit category" when [categoryId] is set.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({
    super.key,
    this.categoryId,
    this.initialKind = TransactionKind.expense,
  });

  final int? categoryId;
  final TransactionKind initialKind;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _name = TextEditingController();
  late TransactionKind _kind = widget.initialKind;
  String _iconKey = AppIcons.categoryIcons.keys.first;
  CategoryColor _color = CategoryColor.orange;
  bool _showOnAddScreen = true;
  bool _saving = false;

  /// The category being edited, once loaded.
  CategoryRow? _editing;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (_isEdit) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    final row = await ref
        .read(categoryRepositoryProvider)
        .getById(widget.categoryId!);
    if (row == null || !mounted) return;
    setState(() {
      _editing = row;
      _name.text = row.name;
      _kind = row.kind;
      _iconKey = row.iconKey;
      _color = CategoryColor.fromKey(row.colorKey);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<CategoryRow> get _sameKind =>
      ref.read(categoriesProvider(_kind)).value ?? const [];

  /// An error to show under the name, or null when the name is fine.
  String? get _nameError {
    final name = _name.text.trim().toLowerCase();
    if (name.isEmpty) return null;
    final taken = _sameKind.any(
      (c) => c.name.toLowerCase() == name && c.id != _editing?.id,
    );
    return taken ? 'You already have a category with this name.' : null;
  }

  bool get _canSave =>
      !_saving && _name.text.trim().isNotEmpty && _nameError == null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(categoryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();

    if (_editing case final row?) {
      await repo.update(
        row.id,
        name: name,
        iconKey: _iconKey,
        colorKey: _color.name,
      );
    } else {
      final before = _sameKind;
      final id = await repo.add(
        name: name,
        kind: _kind,
        iconKey: _iconKey,
        colorKey: _color.name,
      );
      // "Show on add screen": take the last quick-add slot.
      final slots = quickAddSlots(_kind);
      if (_showOnAddScreen && before.length >= slots) {
        final ids = before.map((c) => c.id).toList()..insert(slots - 1, id);
        await repo.reorder(ids);
      }
    }
    if (!mounted) return;
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Category saved' : 'Category created'),
        ),
      );
  }

  Future<void> _remove() async {
    final row = _editing;
    if (row == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove “${row.name}”?'),
        content: const Text(
          'It will no longer be offered when you add a transaction. '
          'Past transactions keep this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: context.colors.expense),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await ref.read(categoryRepositoryProvider).archive(row.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = AppIcons.categoryIcons[_iconKey] ?? AppIcons.box;
    final brightness = Theme.of(context).brightness;
    final tint = _color.resolve(brightness);
    final sameKind = ref.watch(categoriesProvider(_kind)).value ?? const [];
    final slots = quickAddSlots(_kind);
    final lastQuick = sameKind.length >= slots ? sameKind[slots - 1] : null;
    // Keep at least one category of each kind.
    final canRemove = _isEdit && sameKind.length > 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _isEdit ? 'Edit category' : 'New category',
              onClose: () => context.pop(),
              onSave: _canSave ? _save : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  // Preview.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        CategoryIconTile(
                          icon: icon,
                          color: _color,
                          size: 72,
                          iconSize: 34,
                          radius: 22,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Preview',
                          style: AppText.caption13Regular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: AppText.small12.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _name,
                          autofocus: !_isEdit,
                          maxLength: 40,
                          textCapitalization: TextCapitalization.sentences,
                          style: AppText.body17.copyWith(fontSize: 18),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            counterText: '',
                            hintText: 'For example, Gym',
                            hintStyle: AppText.body17.copyWith(
                              fontSize: 18,
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                        if (_nameError case final error?) ...[
                          const SizedBox(height: 6),
                          Text(
                            error,
                            style: AppText.small12.copyWith(color: c.expense),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Type'),
                  // The type of an existing category cannot change, because
                  // its transactions are already expenses or income.
                  IgnorePointer(
                    ignoring: _isEdit,
                    child: Opacity(
                      opacity: _isEdit ? 0.6 : 1,
                      child: SegmentedTabs(
                        options: [
                          SegmentOption(
                            TransactionKind.expense,
                            'Expense',
                            selectedColor: c.expense,
                          ),
                          SegmentOption(
                            TransactionKind.income,
                            'Income',
                            selectedColor: c.income,
                          ),
                        ],
                        selected: _kind,
                        onChanged: (k) => setState(() => _kind = k),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Icon'),
                  AppCard(
                    child: GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.98,
                      children: [
                        for (final MapEntry(key: key, value: iconData)
                            in AppIcons.categoryIcons.entries)
                          _IconOption(
                            icon: iconData,
                            label: '$key icon',
                            selected: key == _iconKey,
                            tint: tint,
                            onTap: () => setState(() => _iconKey = key),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Color'),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    // Wraps to a second line on narrow screens.
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 14,
                      children: [
                        for (final cc in CategoryColor.pickable)
                          _ColorOption(
                            color: cc.resolve(brightness),
                            name: cc.name,
                            selected: cc == _color,
                            onTap: () => setState(() => _color = cc),
                          ),
                      ],
                    ),
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: MergeSemantics(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Show on add screen',
                                    style: AppText.body15,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastQuick == null
                                        ? 'There is a free quick-add slot'
                                        : 'Replaces the last quick-add slot '
                                              '(${lastQuick.name})',
                                    style: AppText.small12Regular.copyWith(
                                      color: c.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _showOnAddScreen,
                              activeTrackColor: c.primary,
                              activeThumbColor: Colors.white,
                              onChanged: (v) =>
                                  setState(() => _showOnAddScreen = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _isEdit ? 'Save changes' : 'Create category',
                    onPressed: _canSave ? _save : null,
                  ),
                  if (canRemove) ...[
                    const SizedBox(height: 4),
                    TextActionButton(
                      label: 'Remove category',
                      icon: AppIcons.trash,
                      color: c.expense,
                      onPressed: _remove,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton.raised(
                  icon: AppIcons.close,
                  semanticLabel: 'Close',
                  onTap: onClose,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSave,
                  child: Text(
                    'Save',
                    style: AppText.body16Strong.copyWith(
                      color: onSave == null ? c.textTertiary : c.textPrimary,
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline13.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.tint,
    required this.onTap,
  });

  final AppIconData icon;
  final String label;
  final bool selected;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: selected ? BorderSide(color: tint, width: 2) : BorderSide.none,
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? tint.withValues(alpha: 0.14) : c.surfaceMuted,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Center(
            child: AppIcon(
              icon,
              size: 22,
              color: selected ? tint : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '$name color',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    // A ring around the selected color.
                    BoxShadow(color: color, spreadRadius: 5),
                    BoxShadow(color: c.surface, spreadRadius: 3),
                  ]
                : null,
          ),
          child: selected
              ? AppIcon(
                  AppIcons.check,
                  size: 16,
                  strokeWidth: 2.4,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
