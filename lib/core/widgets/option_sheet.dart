import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_icon.dart';

/// One row in an option sheet.
class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    this.leading,
    this.subtitle,
  });

  final T value;
  final String label;
  final Widget? leading;
  final String? subtitle;
}

/// Bottom sheet with a title and a list of options. The selected option
/// has a check mark. Returns the picked value, or null if dismissed.
///
/// [footer] is an optional widget under the list, like a link.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
  Widget? footer,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(title, style: AppText.heading17),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  children: [
                    for (final o in options)
                      ListTile(
                        minTileHeight: 52,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: o.leading,
                        title: Text(
                          o.label,
                          style: o.value == selected
                              ? AppText.body15Strong
                              : AppText.body15,
                        ),
                        subtitle: o.subtitle == null
                            ? null
                            : Text(
                                o.subtitle!,
                                style: AppText.caption13Regular.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                        trailing: o.value == selected
                            ? AppIcon(AppIcons.check, color: c.textPrimary)
                            : null,
                        selected: o.value == selected,
                        onTap: () => Navigator.pop(context, o.value),
                      ),
                  ],
                ),
              ),
              ?footer,
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
