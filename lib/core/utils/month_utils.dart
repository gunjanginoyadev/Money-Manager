import 'package:intl/intl.dart';

class MonthUtils {
  MonthUtils._();

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String formatMonthYear(DateTime month, {String locale = 'en_IN'}) {
    return DateFormat.yMMMM(locale).format(startOfMonth(month));
  }

  static DateTime addMonths(DateTime m, int delta) =>
      DateTime(m.year, m.month + delta);

  static DateTime clampPast(DateTime m, {DateTime? earliest}) {
    final e = earliest ?? DateTime(2000);
    if (m.isBefore(e)) return startOfMonth(e);
    return startOfMonth(m);
  }

  static bool isBeforeMonth(DateTime a, DateTime b) {
    if (a.year != b.year) return a.year < b.year;
    return a.month < b.month;
  }
}
