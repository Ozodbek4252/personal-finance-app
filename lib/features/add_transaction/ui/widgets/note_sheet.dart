import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/buttons.dart';

/// Bottom sheet with a text field for the note.
/// Returns the text ("" to remove the note), or null if dismissed.
Future<String?> showNoteSheet(BuildContext context, {String? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _NoteSheet(initial: initial),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({this.initial});

  final String? initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() => Navigator.pop(context, _text.text);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: c.divider),
    );
    return Padding(
      // Move up above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text('Note', style: AppText.heading17),
              ),
              TextField(
                controller: _text,
                autofocus: true,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _done(),
                style: AppText.body15,
                decoration: InputDecoration(
                  hintText: 'For example, Korzinka',
                  hintStyle: AppText.body15Regular.copyWith(
                    color: c.textTertiary,
                  ),
                  filled: true,
                  fillColor: c.background,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: c.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Done', onPressed: _done),
            ],
          ),
        ),
      ),
    );
  }
}
