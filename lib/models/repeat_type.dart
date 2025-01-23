enum RepeatType {
  never,
  hourly,
  daily,
  weekdays,
  weekends,
  weekly,
  monthly,
  yearly,
  custom;

  String getLocalizedName({int? customDays}) {
    switch (this) {
      case RepeatType.never:
        return '永不';
      case RepeatType.hourly:
        return '每小时';
      case RepeatType.daily:
        return '每天';
      case RepeatType.weekdays:
        return '工作日';
      case RepeatType.weekends:
        return '周末';
      case RepeatType.weekly:
        return '每周';
      case RepeatType.monthly:
        return '每月';
      case RepeatType.yearly:
        return '每年';
      case RepeatType.custom:
        if (customDays != null) {
          return '每$customDays天';
        }
        return '自定义';
    }
  }

  DateTime? getNextOccurrence(DateTime from, {int? customDays}) {
    final currentTime = DateTime.now();
    DateTime? next = from;
    while (next != null && next.isBefore(currentTime)) {
      next = __getNextOccurrence(next, customDays: customDays);
    }
    return next;
  }

  DateTime? __getNextOccurrence(DateTime from, {int? customDays}) {
    if (this == RepeatType.never) return null;

    final next =
        DateTime(from.year, from.month, from.day, from.hour, from.minute);

    switch (this) {
      case RepeatType.never:
        return null;
      case RepeatType.hourly:
        return next.add(const Duration(hours: 1));
      case RepeatType.daily:
        return next.add(const Duration(days: 1));

      case RepeatType.weekdays:
        do {
          next.add(const Duration(days: 1));
        } while (next.weekday > 5 || next.weekday < 1);
        return next;

      case RepeatType.weekends:
        do {
          next.add(const Duration(days: 1));
        } while (next.weekday != 6 && next.weekday != 7);
        return next;

      case RepeatType.weekly:
        return next.add(const Duration(days: 7));

      case RepeatType.monthly:
        if (next.month == 12) {
          return DateTime(next.year + 1, 1, next.day, next.hour, next.minute);
        } else {
          return DateTime(
              next.year, next.month + 1, next.day, next.hour, next.minute);
        }

      case RepeatType.yearly:
        return DateTime(
            next.year + 1, next.month, next.day, next.hour, next.minute);

      case RepeatType.custom:
        if (customDays != null && customDays > 0) {
          return next.add(Duration(days: customDays));
        }
        return null;

      default:
        return null;
    }
  }
}
