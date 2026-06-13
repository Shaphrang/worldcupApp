import 'package:intl/intl.dart';

class DateTimeUtils {
  static final _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static String format(DateTime? value) => value == null ? 'TBA' : _dateTime.format(value.toLocal());
  static String countdown(DateTime? target) {
    if (target == null) return 'Schedule TBA';
    final diff = target.toLocal().difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return '${diff.inMinutes.clamp(0, 59)}m';
  }
  static DateTime? parse(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
}
