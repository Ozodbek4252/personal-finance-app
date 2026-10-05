import 'package:intl/intl.dart';

import '../../../core/format/date_format.dart';
import '../../../core/time/clock.dart';
import '../../transactions/domain/transaction_filter.dart';

/// The size of one period on the Statistics screen.
enum PeriodUnit {
  week('Week'),
  month('Month'),
  year('Year');

  const PeriodUnit(this.label);
  final String label;
}

/// One week (Monday to Sunday), month or year.
class StatPeriod {
  /// The period of [unit] that contains [day].
  factory StatPeriod.containing(PeriodUnit unit, DateTime day) {
    final start = switch (unit) {
      // Weeks start on Monday.
      PeriodUnit.week => DateTime(
        day.year,
        day.month,
        day.day - (day.weekday - DateTime.monday),
      ),
      PeriodUnit.month => monthStart(day),
      PeriodUnit.year => DateTime(day.year),
    };
    return StatPeriod._(unit, start);
  }

  const StatPeriod._(this.unit, this.start);

  final PeriodUnit unit;

  /// First day of the period, at midnight.
  final DateTime start;

  /// First day after the period.
  DateTime get end => _shift(1).start;

  DateRange get range => DateRange(start, end);

  StatPeriod get previous => _shift(-1);
  StatPeriod get next => _shift(1);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// [count] periods ending with this one, oldest first.
  List<StatPeriod> lastN(int count) => [
    for (var i = count - 1; i >= 0; i--) _shift(-i),
  ];

  StatPeriod _shift(int n) => StatPeriod._(unit, switch (unit) {
    PeriodUnit.week => DateTime(start.year, start.month, start.day + 7 * n),
    PeriodUnit.month => shiftMonths(start, n),
    PeriodUnit.year => DateTime(start.year + n),
  });

  /// Title under the tabs: "September 2026", "21 – 27 Sep 2026", "2026".
  String get title => switch (unit) {
    PeriodUnit.week =>
      '${DateText.range(start, end.subtract(const Duration(days: 1)))} '
          '${end.subtract(const Duration(days: 1)).year}',
    PeriodUnit.month => DateText.monthYear(start),
    PeriodUnit.year => '${start.year}',
  };

  /// Chart label: "Sep", "21 Sep" or "2026".
  String get shortLabel => switch (unit) {
    PeriodUnit.week => DateFormat('d MMM').format(start),
    PeriodUnit.month => DateText.monthShort(start),
    PeriodUnit.year => '${start.year}',
  };

  /// Label in the small totals grid: "September", "21 Sep", "2026".
  String get mediumLabel => switch (unit) {
    PeriodUnit.month => DateText.month(start),
    _ => shortLabel,
  };

  /// How to name this period when it is the one before the selected one:
  /// "August", "last week", "2025".
  String get asPrevious => switch (unit) {
    PeriodUnit.week => 'last week',
    PeriodUnit.month => DateText.month(start),
    PeriodUnit.year => '${start.year}',
  };

  /// "this month", "this week", "this year".
  String get thisName => 'this ${unit.name}';

  /// "in September", "in the week of 21 Sep", "in 2026".
  String get inName => switch (unit) {
    PeriodUnit.week => 'in the week of $shortLabel',
    PeriodUnit.month => 'in ${DateText.month(start)}',
    PeriodUnit.year => 'in ${start.year}',
  };

  @override
  bool operator ==(Object other) =>
      other is StatPeriod && other.unit == unit && other.start == start;

  @override
  int get hashCode => Object.hash(unit, start);
}
