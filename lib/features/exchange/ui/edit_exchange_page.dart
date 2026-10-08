import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/buttons.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/providers/data_providers.dart';
import 'exchange_form.dart';

/// Changes a saved exchange with the same form as a new one.
class EditExchangePage extends ConsumerStatefulWidget {
  const EditExchangePage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EditExchangePage> createState() => _EditExchangePageState();
}

class _EditExchangePageState extends ConsumerState<EditExchangePage> {
  /// The exchange as it was when the page opened. Kept, so the form
  /// does not start over when the database changes.
  ExchangeDetails? _original;

  @override
  Widget build(BuildContext context) {
    _original ??= ref.watch(exchangeProvider(widget.id)).value;
    final original = _original;

    return Scaffold(
      body: SafeArea(
        // The form scrolls inside, so its keypad stays at the bottom.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleIconButton.raised(
                    icon: AppIcons.close,
                    semanticLabel: 'Close',
                    onTap: () => context.pop(),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Edit exchange',
                        textAlign: TextAlign.center,
                        style: AppText.heading17,
                      ),
                    ),
                  ),
                  // Same width as the close button, so the title stays
                  // centered.
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 16),
              if (original != null)
                Expanded(child: ExchangeForm(editing: original)),
            ],
          ),
        ),
      ),
    );
  }
}
