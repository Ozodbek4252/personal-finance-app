import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/theme/app_colors.dart';
import 'package:personal_finance/core/widgets/highlighted_text.dart';

void main() {
  test('marks every match, ignoring case', () {
    final spans = HighlightedText.highlightSpans(
      'Taxi · MyTaxi · 19:40',
      'taxi',
      AppColors.light,
    );
    expect(spans.map((s) => s.text), ['Taxi', ' · My', 'Taxi', ' · 19:40']);
    expect(spans[0].style?.background, isNotNull);
    expect(spans[1].style, isNull);
  });

  test('no query gives the plain text', () {
    final spans = HighlightedText.highlightSpans(
      'Korzinka',
      ' ',
      AppColors.light,
    );
    expect(spans.single.text, 'Korzinka');
  });
}
