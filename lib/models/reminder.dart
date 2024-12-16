class Reminder {
  final int? id;
  final String title;
  final String? notes;
  final String? url;
  final DateTime? dueDate;
  final bool isCompleted;
  final int priority;
  final String? list;

  Reminder({
    this.id,
    required this.title,
    this.notes,
    this.url,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 0,
    this.list,
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
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      url: map['url'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] as int? ?? 0,
      list: map['list'] as String?,
    );
  }

  @override
  String toString() {
    return 'Reminder{id: $id, title: $title, dueDate: $dueDate, isCompleted: $isCompleted, priority: $priority}';
  }
} 