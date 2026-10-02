import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// One option inside [SegmentedTabs].
class SegmentOption<T> {
  const SegmentOption(this.value, this.label, {this.selectedColor});

  final T value;
  final String label;

  /// Text color when selected. Defaults to the primary text color.
  /// "Expense" uses the expense color, "Income" the income color.
  final Color? selectedColor;
}

/// Equal-width tabs on a muted track, like "Week · Month · Year"
/// or "Expense · Income". The selected tab is a raised white pill.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Segment(
                option: options[i],
                isSelected: options[i].value == selected,
                onTap: () => onChanged(options[i].value),
                colors: c,
                brightness: brightness,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.brightness,
  });

  final SegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColors colors;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.tile);
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? colors.surface : colors.surface.withAlpha(0),
            borderRadius: radius,
            boxShadow: isSelected ? AppShadows.card(brightness) : null,
          ),
          child: Text(
            option.label,
            style: isSelected
                ? AppText.label14Strong.copyWith(
                    color: option.selectedColor ?? colors.textPrimary,
                  )
                : AppText.label14.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
