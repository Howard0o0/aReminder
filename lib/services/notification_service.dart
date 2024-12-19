import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/toast_utils.dart';
import '../services/api_service.dart';

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
              locked: false,
              defaultColor: Colors.blue,
              ledColor: Colors.blue,
              enableVibration: true,
              playSound: true,
              criticalAlerts: true,
            )
          ],
          debug: true);

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

  Future<void> createReminderNotification({
    required int id,
    required String title,
    String? body,
    bool isOverdue = false,
    DateTime? scheduleTime,
  }) async {
    try {
      final content = NotificationContent(
        id: id,
        channelKey: 'scheduled_channel',
        title: title,
        body: body ?? '',
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        criticalAlert: true,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
      );

      final actionButtons = [
        NotificationActionButton(
          key: 'MARK_COMPLETED',
          label: '标记完成',
          actionType: ActionType.SilentAction,
        ),
      ];

      if (scheduleTime != null) {
        await AwesomeNotifications().createNotification(
          content: content,
          schedule: NotificationCalendar.fromDate(
            date: scheduleTime,
            preciseAlarm: true,
            allowWhileIdle: true,
            repeats: false,
          ),
          actionButtons: actionButtons,
        );
      } else {
        await AwesomeNotifications().createNotification(
          content: content,
          actionButtons: actionButtons,
        );
      }

      print('通知创建成功: ID=$id');
    } catch (e) {
      print('创建通知失败: $e');
      rethrow;
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.id == null || reminder.dueDate == null) return;

    final now = DateTime.now();
    if (reminder.dueDate!.isBefore(now)) {
      // ToastUtils.show('请选择一个未来的时间');
      return;
    }

    await AwesomeNotifications().cancel(reminder.id!);
    
    await createReminderNotification(
      id: reminder.id!,
      title: reminder.title,
      body: reminder.notes,
      scheduleTime: reminder.dueDate,
    );

    ApiService.addAppReport(
        'Success scheduled a reminder. [reminder: $reminder] [id: $reminder.id] [title: $reminder.title] [notes: $reminder.notes] [dueDate: $reminder.dueDate]');
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
