import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../shell/placeholder_body.dart';

enum TransactionKind { expense, income }

/// Full-screen "Add expense" / "Add income" page.
/// Placeholder until Task 6; only the header works.
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, required this.initialKind});

  final TransactionKind initialKind;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late var _kind = widget.initialKind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcons.close,
                    semanticLabel: 'Close',
                    onTap: () => context.pop(),
                  ),
                  Expanded(
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
                      onChanged: (kind) => setState(() => _kind = kind),
                    ),
                  ),
                  // Keeps the tabs centered, like the design.
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PlaceholderCard(
                message: _kind == TransactionKind.expense
                    ? 'Add expense is built in Task 6.'
                    : 'Add income is built in Task 6.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
