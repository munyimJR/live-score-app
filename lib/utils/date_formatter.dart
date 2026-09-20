import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatFull(dynamic date) {
    if (date == null) return 'Date TBD';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Date TBD';
    }

    final DateFormat formatter = DateFormat('EEE, d MMM yyyy • h:mm a');
    return formatter.format(dateTime);
  }

  static String formatCardDate(dynamic date) {
    if (date == null) return 'TBD';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'TBD';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = DateFormat('h:mm a').format(dateTime);

    if (matchDay == today) {
      return 'Today • $timeString';
    } else if (matchDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow • $timeString';
    } else if (matchDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • $timeString';
    } else {
      return DateFormat('d MMM • h:mm a').format(dateTime);
    }
  }
}
