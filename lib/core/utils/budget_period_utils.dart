import 'package:intl/intl.dart';

/// Payday-based budget cycles: each period starts on [salaryDayOfMonth] (1–31; clamped per month).
class BudgetPeriodUtils {
  BudgetPeriodUtils._();

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Local calendar date (no time component) for comparisons.
  static DateTime calendarDay(DateTime d) => _dateOnly(d);

  /// Calendar day for payday in [year]/[month], clamped (e.g. 31 → last day in Feb).
  static DateTime paydayInMonth(int year, int month, int preferredDay) {
    final last = DateTime(year, month + 1, 0).day;
    final day = preferredDay.clamp(1, last);
    return DateTime(year, month, day);
  }

  /// Start of the budget period that contains [local] (local calendar date).
  static DateTime startOfBudgetPeriodContaining(
    DateTime local,
    int salaryDayOfMonth,
  ) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final t = _dateOnly(local);
    final thisPay = paydayInMonth(t.year, t.month, pay);
    if (!t.isBefore(thisPay)) {
      return thisPay;
    }
    final prevMonth = t.month == 1 ? 12 : t.month - 1;
    final prevYear = t.month == 1 ? t.year - 1 : t.year;
    return paydayInMonth(prevYear, prevMonth, pay);
  }

  /// First day of the **next** budget period after [periodStart].
  static DateTime nextBudgetPeriodStartAfter(
    DateTime periodStart,
    int salaryDayOfMonth,
  ) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final y = periodStart.year;
    final m = periodStart.month;
    if (m == 12) {
      return paydayInMonth(y + 1, 1, pay);
    }
    return paydayInMonth(y, m + 1, pay);
  }

  /// First day of the budget period **before** [periodStart].
  static DateTime previousBudgetPeriodStart(
    DateTime periodStart,
    int salaryDayOfMonth,
  ) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final y = periodStart.year;
    final m = periodStart.month;
    if (m == 1) {
      return paydayInMonth(y - 1, 12, pay);
    }
    return paydayInMonth(y, m - 1, pay);
  }

  /// Inclusive calendar days from [today] through end of period (last day before next payday).
  static int daysLeftInclusiveInPeriod(
    DateTime today,
    int salaryDayOfMonth,
  ) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final t = _dateOnly(today);
    final start = startOfBudgetPeriodContaining(today, pay);
    final nextStart = nextBudgetPeriodStartAfter(start, pay);
    final lastDay = _dateOnly(nextStart.subtract(const Duration(days: 1)));
    if (t.isAfter(lastDay)) return 1;
    return lastDay.difference(t).inDays + 1;
  }

  static bool isDateInBudgetPeriod(
    DateTime effective,
    DateTime periodStart,
    int salaryDayOfMonth,
  ) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final d = _dateOnly(effective);
    final next = nextBudgetPeriodStartAfter(periodStart, pay);
    return !d.isBefore(_dateOnly(periodStart)) && d.isBefore(next);
  }

  /// Human-readable range, e.g. `15 Jan – 14 Feb 2026`.
  static String formatBudgetPeriodRange(
    DateTime periodStart,
    int salaryDayOfMonth, {
    String locale = 'en_IN',
  }) {
    final pay = salaryDayOfMonth.clamp(1, 31);
    final next = nextBudgetPeriodStartAfter(periodStart, pay);
    final end = next.subtract(const Duration(days: 1));
    final df = DateFormat('d MMM', locale);
    final yf = DateFormat('yyyy', locale);
    if (periodStart.year == end.year) {
      return '${df.format(periodStart)} – ${df.format(end)} ${yf.format(periodStart)}';
    }
    return '${df.format(periodStart)} ${yf.format(periodStart)} – ${df.format(end)} ${yf.format(end)}';
  }
}
