import 'package:intl/intl.dart';

/// Formats dates the way the design shows them (English, 24-hour time).
abstract final class DateText {
  static final _weekdayDayMonth = DateFormat('EEEE, d MMMM');
  static final _monthYear = DateFormat('MMMM y');
  static final _detail = DateFormat('EEE, d MMM y');
  static final _time = DateFormat('HH:mm');
  static final _dayMonth = DateFormat('d MMM');
  static final _fullDate = DateFormat('dd MMM y');
  static final _weekday = DateFormat('EEEE');
  static final _monthShort = DateFormat('MMM');
  static final _monthLong = DateFormat('MMMM');

  /// "Wednesday, 30 September" (dashboard header).
  static String weekdayDayMonth(DateTime d) => _weekdayDayMonth.format(d);

  /// "September 2026".
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// "September".
  static String month(DateTime d) => _monthLong.format(d);

  /// "Aug".
  static String monthShort(DateTime d) => _monthShort.format(d);

  /// "01 Sep 2026" (date fields in the filter sheet).
  static String fullDate(DateTime d) => _fullDate.format(d);

  /// "13:40".
  static String time(DateTime d) => _time.format(d);

  /// "Wed, 30 Sep 2026 · 13:40" (transaction details).
  static String detail(DateTime d) => '${_detail.format(d)} · ${time(d)}';

  /// "30 Sep".
  static String dayMonth(DateTime d) => _dayMonth.format(d);

  /// "19 Sep, 23:10" (search results).
  static String dayMonthTime(DateTime d) =>
      '${_dayMonth.format(d)}, ${time(d)}';

  /// "Today, 13:40", "Yesterday, 09:12" or "27 Sep, 16:30".
  static String relativeDayTime(DateTime d, {required DateTime now}) {
    final label = _relativeDay(d, now);
    return label == null ? dayMonthTime(d) : '$label, ${time(d)}';
  }

  /// "Today", "Yesterday" or "27 Sep".
  static String shortDay(DateTime d, {required DateTime now}) =>
      _relativeDay(d, now) ?? _dayMonth.format(d);

  /// Header of a day group in the transaction list:
  /// "Today · 30 Sep", "Yesterday · 29 Sep", "Sunday · 27 Sep".
  static String dayGroup(DateTime d, {required DateTime now}) {
    final label = _relativeDay(d, now) ?? _weekday.format(d);
    return '$label · ${_dayMonth.format(d)}';
  }

  /// "1 – 30 Sep" when both dates are in the same month,
  /// else "28 Aug – 3 Sep".
  static String range(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month) {
      return '${from.day} – ${_dayMonth.format(to)}';
    }
    return '${_dayMonth.format(from)} – ${_dayMonth.format(to)}';
  }

  /// "Today", "Yesterday" or null for any other day.
  static String? _relativeDay(DateTime d, DateTime now) {
    // UTC dates avoid 23-hour days around daylight saving changes.
    final day = DateTime.utc(d.year, d.month, d.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return null;
  }
}
