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

      // 请求所有必要的权限
      await _requestRequiredPermissions();
      
      print('通知服务初始化成功');
    } catch (e) {
      print('通知服务初始化失败: $e');
      rethrow;
    }
  }

  Future<void> _requestRequiredPermissions() async {
    // 请求通知权限
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // 只在 Android 上执行
    if (!Platform.isAndroid) return;

    // 检查 Android 版本
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final androidVersion = deviceInfo.version.sdkInt;

    // Android 12 及以上需要请求精确闹钟权限
    if (androidVersion >= 31) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    // 请求忽略电池优化
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
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
      print('准备创建通知:');
      print('ID: ${reminder.id}');
      print('标题: ${reminder.title}');
      print('时间: ${reminder.dueDate}');

      bool success = await AwesomeNotifications().createNotification(
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

      print('通知创建${success ? '成功' : '失败'}');

      if (success) {
        final schedules = await AwesomeNotifications().listScheduledNotifications();
        print('当前计划的通知:');
        for (var schedule in schedules) {
          print('ID: ${schedule.content?.id}, 计划时间: ${schedule.schedule?.toMap()}');
        }
      }

    } catch (e) {
      print('设置通知失败: $e');
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      print('通知 $id 已取消');
    } catch (e) {
      print('取消通知失败: $e');
      rethrow;
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await AwesomeNotifications().cancelAll();
      print('所有通知已取消');
    } catch (e) {
      print('取消所有通知失败: $e');
      rethrow;
    }
  }
} 