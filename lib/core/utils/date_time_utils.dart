class DateTimeUtils {
  static DateTime? parse(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String format(DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    final day = _two(local.day);
    final month = _monthShort(local.month);
    final year = local.year;

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = _two(local.minute);
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year • $hour12:$minute $amPm';
  }

  static String formatShort(DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    final day = _two(local.day);
    final month = _monthShort(local.month);

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = _two(local.minute);
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '$day $month • $hour12:$minute $amPm';
  }

  static String timeOnly(DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = _two(local.minute);
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $amPm';
  }

  static String dateOnly(DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    return '${_two(local.day)} ${_monthShort(local.month)} ${local.year}';
  }

  static String countdown(DateTime? target) {
    if (target == null) return '—';

    final diff = target.toLocal().difference(DateTime.now());

    if (diff.isNegative) {
      return 'Started';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    }

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }

  static String closeIn(DateTime? value) {
    if (value == null) return '—';

    final diff = value.toLocal().difference(DateTime.now());

    if (diff.isNegative) {
      return 'Closed';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    }

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  static bool isSameLocalDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;

    final x = a.toLocal();
    final y = b.toLocal();

    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}