import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Text where every match of [query] gets a soft highlight, like a
/// search result. Matching ignores upper and lower case.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(children: highlightSpans(text, query, c)),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Splits [text] into plain and highlighted parts.
  static List<TextSpan> highlightSpans(String text, String query, AppColors c) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [TextSpan(text: text)];
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final i = lower.indexOf(q, start);
      if (i < 0) break;
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(
        TextSpan(
          text: text.substring(i, i + q.length),
          style: TextStyle(
            color: c.textPrimary,
            background: Paint()..color = c.highlight,
          ),
        ),
      );
      start = i + q.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }
}
