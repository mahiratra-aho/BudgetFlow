import 'package:intl/intl.dart';

// Utilitaires de formatage de dates (FR)
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dayMonth = DateFormat('d MMM', 'fr_FR');
  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'fr_FR');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _shortMonth = DateFormat('MMM', 'fr_FR');
  static final DateFormat _time = DateFormat('HH:mm', 'fr_FR');

  static String formatDayMonth(DateTime dt) => _dayMonth.format(dt);
  static String formatFull(DateTime dt) => _fullDate.format(dt);
  static String formatMonthYear(DateTime dt) => _monthYear.format(dt);
  static String formatShortMonth(DateTime dt) => _shortMonth.format(dt);
  static String formatTime(DateTime dt) => _time.format(dt);

  // Libellé relatif : aujourd'hui, hier, ou date
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) return 'Il y a $diff jours';
    return formatDayMonth(dt);
  }

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Nom du mois (capitalisé)
  static String monthName(int month) {
    final dt = DateTime(2024, month);
    return DateFormat('MMMM', 'fr_FR').format(dt);
  }
}
