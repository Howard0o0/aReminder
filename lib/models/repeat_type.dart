enum RepeatType {
  never,
  daily,
  weekdays,
  weekends,
  weekly,
  monthly;

  String get localizedName {
    switch (this) {
      case RepeatType.never:
        return '永不';
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
    }
  }

  DateTime? getNextOccurrence(DateTime from) {
    if (this == RepeatType.never) return null;

    final next = DateTime(from.year, from.month, from.day, from.hour, from.minute);
    
    switch (this) {
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
          return DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
        }
      
      default:
        return null;
    }
  }
} 