import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class RemindersProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;
  List<Reminder> get incompleteReminders => _reminders.where((r) => !r.isCompleted).toList();
  List<Reminder> get completedReminders => _reminders.where((r) => r.isCompleted).toList();

  Future<void> loadReminders() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    final id = await _db.insertReminder(reminder);
    final newReminder = Reminder(
      id: id,
      title: reminder.title,
      notes: reminder.notes,
      dueDate: reminder.dueDate,
      isCompleted: reminder.isCompleted,
      priority: reminder.priority,
      list: reminder.list,
    );
    
    _reminders.add(newReminder);
    if (newReminder.dueDate != null) {
      await _notifications.scheduleReminder(newReminder);
    }
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _db.updateReminder(reminder);
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      if (reminder.dueDate != null) {
        await _notifications.scheduleReminder(reminder);
      } else {
        await _notifications.cancelReminder(reminder.id!);
      }
      notifyListeners();
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _notifications.cancelReminder(id);
      
      await _db.deleteReminder(id);
      
      _reminders.removeWhere((reminder) => reminder.id == id);
      
      notifyListeners();
      
      print('提醒已删除: ID=$id');
    } catch (e) {
      print('删除提醒失败: $e');
      rethrow;
    }
  }

  Future<void> toggleComplete(Reminder reminder) async {
    final updatedReminder = Reminder(
      id: reminder.id,
      title: reminder.title,
      notes: reminder.notes,
      dueDate: reminder.dueDate,
      isCompleted: !reminder.isCompleted,
      priority: reminder.priority,
      list: reminder.list,
    );
    
    if (!reminder.isCompleted && updatedReminder.isCompleted) {
      await _notifications.cancelReminder(reminder.id!);
    }
    
    await updateReminder(updatedReminder);
  }
} 