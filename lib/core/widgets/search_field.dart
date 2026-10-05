import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import 'app_icon.dart';

/// White rounded search box with a search icon and a clear button.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Search',
    this.semanticLabel = 'Search',
  });

  /// Current text. The field updates when this changes from outside
  /// (for example after "Clear filters").
  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final String semanticLabel;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _text = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _text.text) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        boxShadow: AppShadows.card(Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.search, color: c.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: widget.semanticLabel,
              textField: true,
              child: TextField(
                controller: _text,
                onChanged: (v) {
                  setState(() {}); // Show or hide the clear button.
                  widget.onChanged(v);
                },
                textInputAction: TextInputAction.search,
                style: AppText.body16Regular,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: AppText.body16Regular.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          if (_text.text.isNotEmpty)
            Semantics(
              container: true,
              button: true,
              label: 'Clear search',
              excludeSemantics: true,
              child: IconButton(
                onPressed: _clear,
                icon: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    AppIcons.close,
                    size: 14,
                    strokeWidth: 2,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
