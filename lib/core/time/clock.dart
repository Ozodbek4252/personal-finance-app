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

/// Midnight on the first day of [d]'s month.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

/// Midnight on the first day of the month after [d]'s month.
DateTime nextMonthStart(DateTime d) => DateTime(d.year, d.month + 1);
