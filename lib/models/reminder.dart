import 'repeat_type.dart';

class Reminder {
  final int? id;
  String title;
  String? notes;
  String? url;
  DateTime? dueDate;
  bool isCompleted;
  int priority;
  String? list;
  RepeatType repeatType;
  int? customRepeatDays;

  Reminder({
    this.id,
    required this.title,
    this.notes,
    this.url,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 0,
    this.list,
    this.repeatType = RepeatType.never,
    this.customRepeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'url': url,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'list': list,
      'repeatType': repeatType.name,
      'custom_repeat_days': customRepeatDays,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      notes: map['notes'],
      url: map['url'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] ?? 0,
      list: map['list'],
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == (map['repeatType'] ?? 'never'),
        orElse: () => RepeatType.never,
      ),
      customRepeatDays: map['custom_repeat_days'],
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? notes,
    String? url,
    DateTime? dueDate,
    bool? isCompleted,
    int? priority,
    String? list,
    RepeatType? repeatType,
    int? customRepeatDays,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      url: url ?? this.url,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      list: list ?? this.list,
      repeatType: repeatType ?? this.repeatType,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
    );
  }

  @override
  String toString() {
    return 'Reminder{id: $id, title: $title, dueDate: $dueDate, isCompleted: $isCompleted, priority: $priority, repeatType: $repeatType, customRepeatDays: $customRepeatDays}';
  }
} 