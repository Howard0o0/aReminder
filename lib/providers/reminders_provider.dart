import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../models/repeat_type.dart';
import '../providers/settings_provider.dart';
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
  List<Reminder> get incompleteReminders =>
      _reminders.where((r) => !r.isCompleted).toList();
  List<Reminder> get completedReminders =>
      _reminders.where((r) => r.isCompleted).toList();

  List<Reminder> get scheduledReminders =>
      _reminders.where((r) => r.dueDate != null && !r.isCompleted).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  Future<void> loadReminders() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> updateBadgeCount() async {
    // 计算逾期且未完成的提醒数量
    final overdueCount = incompleteReminders
        .where((r) => r.dueDate?.isBefore(DateTime.now()) ?? false)
        .length;
    _notifications.updateBadgeCount(overdueCount);
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
      repeatType: reminder.repeatType,
      customRepeatDays: reminder.customRepeatDays,
    );

    if (SettingsProvider.instance.nullTimeAsNow) {
      // 设置为当前时间5秒后
      newReminder.dueDate = DateTime.now().add(const Duration(seconds: 2));
    }

    _reminders.add(newReminder);
    if (newReminder.dueDate != null) {
      await _notifications.scheduleReminder(newReminder);
    }
    notifyListeners();
    print('Reminder added: $newReminder');
    ApiService.addAppReport(
        '成功添加一个提醒事项. [reminder: $newReminder] [id: $newReminder.id] [title: $newReminder.title] [notes: $newReminder.notes] [dueDate: $newReminder.dueDate]');
    updateBadgeCount();
  }

  Future<void> updateReminder(Reminder reminder) async {
    print('updateing reminder: $reminder');

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
    print('Reminder updated: ${reminder}');
    ApiService.addAppReport(
        '成功更新一个提醒事项. [reminder: $reminder] [id: $reminder.id] [title: $reminder.title] [notes: $reminder.notes] [dueDate: $reminder.dueDate]');

    updateBadgeCount();
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _notifications.cancelReminder(id);

      await _db.deleteReminder(id);

      _reminders.removeWhere((reminder) => reminder.id == id);

      notifyListeners();

      print('提醒已删除: ID=$id');
      updateBadgeCount();
    } catch (e) {
      print('删除提醒失败: $e');
      rethrow;
    }
  }

  Future<void> toggleComplete(Reminder reminder) async {
    if (reminder.repeatType != RepeatType.never && reminder.dueDate != null) {
      print(
          '处理重复提醒事项: ${reminder.id}, 重复类型: ${reminder.repeatType}, 自定义天数: ${reminder.customRepeatDays}');
      // 计算下一次提醒时间，传入自定义天数
      final nextDueDate = reminder.repeatType.getNextOccurrence(
        reminder.dueDate!,
        customDays: reminder.customRepeatDays,
      );
      reminder.isCompleted = false;
      reminder.dueDate = nextDueDate;
      print('nextDueDate: $nextDueDate');
    } else {
      reminder.isCompleted = true;
    }

    await _notifications.cancelReminder(reminder.id!);
    await updateReminder(reminder);
    print('app 内标记为完成: ${reminder.id}');
    ApiService.addAppReport(
        'app 内标记为完成. [reminder: $reminder] [id: $reminder.id] [title: $reminder.title] [notes: $reminder.notes] [dueDate: $reminder.dueDate]');
  }

  Future<void> markReminderAsCompleted(int id) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == id);
      print('找到提醒: ${reminder.id}');

      var updatedReminder = reminder;
      updatedReminder.isCompleted = true;

      await toggleComplete(updatedReminder);

      print('通知栏里标记为完成: ID=$id');
      ApiService.addAppReport(
          '通知栏里标记为完成. [reminder: $reminder] [id: $reminder.id] [title: $reminder.title] [notes: $reminder.notes] [dueDate: $reminder.dueDate]');
    } catch (e) {
      print('标记提醒完成失败: $e');
      rethrow;
    }
  }

  Future<void> postponeReminder(int id, Duration duration) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == id);
      print('找到提醒: ${reminder.id}');

      // 创建新的到期时间
      final newDueDate = DateTime.now().add(duration);

      var updatedReminder = reminder;
      updatedReminder.dueDate = newDueDate;
      await updateReminder(updatedReminder);

      print('提醒已推迟 ${duration.inMinutes} 分钟: ID=$id');
      ApiService.addAppReport(
          '提醒已推迟. [reminder: $reminder] [id: $reminder.id] [title: $reminder.title] [推迟时间: ${duration.inMinutes}分钟] [newDueDate: $newDueDate]');
    } catch (e) {
      print('推迟提醒失败: $e');
      rethrow;
    }
  }
}
