import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // 不使用自定义图标
      [
        NotificationChannel(
          channelKey: 'scheduled_channel',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Scheduled notifications for reminders',
          importance: NotificationImportance.Max,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          locked: true,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
        )
      ],
    );

    // 请求权限
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.id == null || reminder.dueDate == null) return;

    final now = DateTime.now();
    if (reminder.dueDate!.isBefore(now)) {
      print('提醒时间已过: ${reminder.dueDate}');
      return;
    }

    try {
      print('准备创建通知:');
      print('ID: ${reminder.id}');
      print('标题: ${reminder.title}');
      print('时间: ${reminder.dueDate}');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.id!,
          channelKey: 'scheduled_channel',
          title: '提醒事项',
          body: reminder.title,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          locked: true,
          criticalAlert: true,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(
          date: reminder.dueDate!,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );

      // 验证通知是否已创建
      final schedules = await AwesomeNotifications().listScheduledNotifications();
      print('当前计划的通知:');
      for (var schedule in schedules) {
        print('ID: ${schedule.content?.id}, 计划时间: ${schedule.schedule?.toMap()}');
      }

    } catch (e) {
      print('设置通知失败: $e');
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
  }
} 