import 'package:intl/intl.dart';

/// Utility class for consistent date/time formatting across the app.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDateTime = DateFormat('MMM d, yyyy • HH:mm');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _timeOnly = DateFormat('HH:mm:ss');
  static final DateFormat _relative = DateFormat('HH:mm');

  /// Formats as "Apr 20, 2026 • 14:30"
  static String fullDateTime(DateTime dateTime) {
    return _fullDateTime.format(dateTime);
  }

  /// Formats as "Apr 20, 2026"
  static String shortDate(DateTime dateTime) {
    return _shortDate.format(dateTime);
  }

  /// Formats as "14:30:05"
  static String timeOnly(DateTime dateTime) {
    return _timeOnly.format(dateTime);
  }

  /// Returns a human-friendly relative time string.
  /// e.g., "Just now", "5 min ago", "2 hours ago", "Yesterday at 14:30"
  static String relative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_relative.format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return _shortDate.format(dateTime);
    }
  }
}
