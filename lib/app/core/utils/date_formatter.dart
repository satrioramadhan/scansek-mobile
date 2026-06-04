import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Date and time formatting utilities (Bahasa Indonesia)
class DateFormatter {
  DateFormatter._(); // Private constructor

  /// Format date: 08 Jan 2026
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = AppConstants.monthsInIndonesian[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  /// Format time: 14:30
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format date time: 08 Jan 2026, 14:30
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)}, ${formatTime(date)}';
  }

  /// Get day name in Indonesian: Senin, Selasa, etc.
  static String getDayName(DateTime date) {
    // DateTime.weekday: Monday=1, Sunday=7
    // Our array: Senin=0, Minggu=6
    int index = date.weekday - 1;
    return AppConstants.daysInIndonesian[index];
  }

  /// Format as "Senin, 08 Jan 2026"
  static String formatFullDate(DateTime date) {
    return '${getDayName(date)}, ${formatDate(date)}';
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get relative date string: "Hari Ini", "Kemarin", or formatted date
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Hari Ini';
    } else if (isYesterday(date)) {
      return 'Kemarin';
    } else {
      return formatDate(date);
    }
  }

  /// Get time ago string: "2 jam yang lalu", "1 hari yang lalu"
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return formatDate(date);
    }
  }

  /// Parse ISO string to DateTime
  static DateTime? parseISOString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Format DateTime to ISO string for API
  static String toISOString(DateTime date) {
    return date.toIso8601String();
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get list of dates for weekly stats (last 7 days including today)
  static List<DateTime> getWeeklyDates() {
    final today = DateTime.now();
    return List.generate(
      AppConstants.weeklyStatsDays,
      (index) => today.subtract(Duration(days: AppConstants.weeklyStatsDays - 1 - index)),
    );
  }

  /// Format number dengan separator (1000 → 1.000)
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }

  /// Format decimal number (2 decimal places)
  static String formatDecimal(double number, {int decimals = 1}) {
    return number.toStringAsFixed(decimals);
  }
}
