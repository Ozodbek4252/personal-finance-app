import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Small dialog with one text field. Returns the text, or null when
/// cancelled. [validate] returns an error message, or null when the
/// text is fine.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String? hint,
  String saveLabel = 'Save',
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter> inputFormatters = const [],
  String? Function(String text)? validate,
  String? suffix,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      initial: initial,
      hint: hint,
      saveLabel: saveLabel,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validate: validate,
      suffix: suffix,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.saveLabel,
    required this.keyboardType,
    required this.inputFormatters,
    required this.validate,
    required this.suffix,
  });

  final String title;
  final String initial;
  final String? hint;
  final String saveLabel;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String)? validate;
  final String? suffix;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String? get _error => widget.validate?.call(_text.text);

  void _save() {
    if (_error == null) Navigator.pop(context, _text.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _text.text.isEmpty ? null : _error,
          suffixText: widget.suffix,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _error == null ? _save : null,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
