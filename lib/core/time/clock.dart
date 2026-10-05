/// Gives the current time. Read it through `clockProvider` instead of
/// calling `DateTime.now()`, so tests and demo mode can control "now".
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock that starts at [start] and then runs at normal speed.
///
/// Debug builds with sample data use it, so "today" is the same day
/// as in the design (30 September 2026).
class ShiftedClock implements Clock {
  ShiftedClock(this.start) : _watch = Stopwatch()..start();

  final DateTime start;
  final Stopwatch _watch;

  @override
  DateTime now() => start.add(_watch.elapsed);
}

/// The day of the month on which a "month" starts (1–28).
///
/// Set from Settings > Month starts on. With 25, the September month runs
/// from 25 September to 24 October. Every month calculation in the app goes
/// through [monthStart], [nextMonthStart] and [shiftMonths].
abstract final class MonthCycle {
  static int startDay = 1;
}

/// Midnight on the first day of the month that contains [d].
DateTime monthStart(DateTime d) {
  final s = MonthCycle.startDay;
  return d.day >= s
      ? DateTime(d.year, d.month, s)
      : DateTime(d.year, d.month - 1, s);
}

/// Midnight on the first day of the month after [d]'s month.
DateTime nextMonthStart(DateTime d) => shiftMonths(monthStart(d), 1);

/// Moves a month start (from [monthStart]) by [n] months.
DateTime shiftMonths(DateTime start, int n) =>
    DateTime(start.year, start.month + n, start.day);
