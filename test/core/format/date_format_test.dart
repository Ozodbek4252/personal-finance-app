import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/format/date_format.dart';

void main() {
  final now = DateTime(2026, 9, 30, 15);

  test('header and month formats', () {
    expect(DateText.weekdayDayMonth(now), 'Wednesday, 30 September');
    expect(DateText.monthYear(now), 'September 2026');
    expect(DateText.monthShort(DateTime(2026, 8)), 'Aug');
  });

  test('detail and short formats', () {
    final d = DateTime(2026, 9, 30, 13, 40);
    expect(DateText.detail(d), 'Wed, 30 Sep 2026 · 13:40');
    expect(
      DateText.dayMonthTime(DateTime(2026, 9, 19, 23, 10)),
      '19 Sep, 23:10',
    );
  });

  test('day group headers', () {
    expect(
      DateText.dayGroup(DateTime(2026, 9, 30, 9), now: now),
      'Today · 30 Sep',
    );
    expect(
      DateText.dayGroup(DateTime(2026, 9, 29), now: now),
      'Yesterday · 29 Sep',
    );
    expect(
      DateText.dayGroup(DateTime(2026, 9, 27), now: now),
      'Sunday · 27 Sep',
    );
  });

  test('relativeDayTime', () {
    expect(
      DateText.relativeDayTime(DateTime(2026, 9, 30, 13, 40), now: now),
      'Today, 13:40',
    );
    expect(
      DateText.relativeDayTime(DateTime(2026, 9, 24, 8, 55), now: now),
      '24 Sep, 08:55',
    );
  });

  test('shortDay', () {
    expect(DateText.shortDay(DateTime(2026, 9, 29, 18), now: now), 'Yesterday');
    expect(DateText.shortDay(DateTime(2026, 9, 27), now: now), '27 Sep');
  });

  test('range', () {
    expect(
      DateText.range(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
      '1 – 30 Sep',
    );
    expect(
      DateText.range(DateTime(2026, 8, 28), DateTime(2026, 9, 3)),
      '28 Aug – 3 Sep',
    );
  });
}
