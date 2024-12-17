import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'scheduled_channel',
            channelName: 'Scheduled Notifications',
            channelDescription: 'Scheduled notifications for reminders',
            importance: NotificationImportance.High,
            defaultPrivacy: NotificationPrivacy.Public,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
            locked: true,
            defaultColor: Colors.blue,
            ledColor: Colors.blue,
            enableVibration: true,
            playSound: true,
            criticalAlerts: true,
          )
        ],
        debug: true
      );

      await _requestRequiredPermissions();
      print('通知服务初始化成功');
    } catch (e) {
      print('通知服务初始化失败: $e');
      rethrow;
    }
  }

  Future<void> _requestRequiredPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    if (!Platform.isAndroid) return;

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final androidVersion = deviceInfo.version.sdkInt;

    if (androidVersion >= 31) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.id == null || reminder.dueDate == null) return;

    final now = DateTime.now();
    if (reminder.dueDate!.isBefore(now)) {
      print('提醒时间已过: ${reminder.dueDate}');
      return;
    }

    try {
      print('准备设置提醒:');
      print('ID: ${reminder.id}');
      print('标题: ${reminder.title}');
      print('时间: ${reminder.dueDate}');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.id!,
          channelKey: 'scheduled_channel',
          title: reminder.title,
          body: reminder.notes ?? '',
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
          repeats: false,
        ),
      );

      print('提醒设置成功');
    } catch (e) {
      print('设置提醒失败: $e');
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      print('提醒 $id 已取消');
    } catch (e) {
      print('取消提醒失败: $e');
      rethrow;
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await AwesomeNotifications().cancelAll();
      print('所有提醒已取消');
    } catch (e) {
      print('取消所有提醒失败: $e');
      rethrow;
    }
  }
} 