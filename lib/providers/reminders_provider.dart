import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class RemindersProvider with ChangeNotifier {
  static RemindersProvider? _instance;
  static Future<RemindersProvider>? _initializingFuture;
  
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  List<Reminder> _reminders = [];
  
  // 私有构造函数
  RemindersProvider._internal();

  // 工厂构造函数
  static Future<RemindersProvider> getInstance() async {
    if (_instance != null) return _instance!;

    // 如果已经在初始化中，返回同一个 Future
    _initializingFuture ??= _initialize();
    return _initializingFuture!;
  }

  // 私有初始化方法
  static Future<RemindersProvider> _initialize() async {
    final provider = RemindersProvider._internal();
    await provider.loadReminders();
    _instance = provider;
    return provider;
  }

  // TODO
  // 分成两个 _reminders
  // 一个是 todoReminders
  // 一个是 completedReminders

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

  Future<void> markReminderAsCompleted(int id) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == id);
      print('找到提醒: ${reminder.id}');

      final updatedReminder = Reminder(
        id: reminder.id,
        title: reminder.title,
        notes: reminder.notes,
        dueDate: reminder.dueDate,
        isCompleted: true,
        priority: reminder.priority,
        list: reminder.list,
      );

      await updateReminder(updatedReminder);

      print('提醒已标记为完成: ID=$id');
    } catch (e) {
      print('标记提醒完成失败: $e');
      rethrow;
    }
  }
} 