// Date formatting and helper functions

import 'package:intl/intl.dart';

class DateHelpers {
  // Format date as "dd MMM yyyy" (e.g., "22 Jan 2026")
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format date as "dd/MM/yyyy"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format datetime as "dd MMM yyyy, hh:mm a"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Format time only as "hh:mm a"
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Get time ago string (e.g., "2 hours ago", "3 days ago")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Get days remaining until deadline
  static int getDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays;
  }

  // Get countdown string (e.g., "5 days left", "2 hours left")
  static String getCountdown(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} left';
    } else {
      return 'Expiring soon';
    }
  }

  // Check if deadline is approaching (within 7 days)
  static bool isDeadlineApproaching(DateTime deadline) {
    final daysRemaining = getDaysRemaining(deadline);
    return daysRemaining >= 0 && daysRemaining <= 7;
  }

  // Calculate SLA deadline from submission time
  static DateTime calculateSLADeadline(DateTime submissionTime, int slaHours) {
    return submissionTime.add(Duration(hours: slaHours));
  }

  // Check if SLA is breached
  static bool isSLABreached(DateTime slaDeadline) {
    return DateTime.now().isAfter(slaDeadline);
  }

  // Get SLA status color indicator
  static String getSLAStatus(DateTime slaDeadline) {
    final now = DateTime.now();
    final difference = slaDeadline.difference(now);

    if (difference.isNegative) {
      return 'breached';
    } else if (difference.inHours < 6) {
      return 'critical';
    } else if (difference.inHours < 24) {
      return 'warning';
    } else {
      return 'normal';
    }
  }
}
