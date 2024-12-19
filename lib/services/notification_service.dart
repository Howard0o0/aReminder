import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/toast_utils.dart';
import '../services/api_service.dart';
import 'package:app_settings/app_settings.dart';
import '../main.dart';

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
              importance: NotificationImportance.Max,
              defaultPrivacy: NotificationPrivacy.Public,
              defaultRingtoneType: DefaultRingtoneType.Notification,
              locked: true,
              defaultColor: Colors.blue,
              ledColor: Colors.blue,
              enableVibration: true,
              playSound: true,
              criticalAlerts: true,
              onlyAlertOnce: false,
              channelShowBadge: true,
            )
          ],
          debug: true);

      // await AwesomeNotifications().requestPermissionToSendNotifications(
      //   channelKey: 'scheduled_channel',
      //   permissions: [
      //     NotificationPermission.Alert,
      //     NotificationPermission.Sound,
      //     NotificationPermission.Badge,
      //     NotificationPermission.Vibration,
      //     NotificationPermission.Light,
      //     NotificationPermission.FullScreenIntent,
      //     NotificationPermission.CriticalAlert,
      //   ],
      // );

      print('通知服务初始化成功');
    } catch (e) {
      print('通知服务初始化失败: $e');
      rethrow;
    }
  }

  Future<void> requestRequiredPermissions() async {
    final permissions = await AwesomeNotifications().checkPermissionList();
    print('原始通知权限状态: $permissions');

    final context = MyApp.navigatorKey.currentState?.context;

    showCupertinoDialog(
      context: context!,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: CupertinoAlertDialog(
          title: const Text("设置通知权限"),
          content: const Text(
            '''为了更好的使用体验
请到设置里开启以下通知权限: 

1. 锁屏通知: 在锁屏状态下显示通知
2. 横幅通知: 在屏幕顶部显示通知
3. 角标通知: 在应用图标上显示角标
''',
            textAlign: TextAlign.left,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                print('忽略');
                Navigator.pop(context);
              },
              child: const Text(
                '忽略',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                print('请求通知权限');
                AwesomeNotifications().requestPermissionToSendNotifications(
                    channelKey: 'scheduled_channel');
                Navigator.pop(context);
              },
              child: const Text(
                '去设置',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final androidVersion = deviceInfo.version.sdkInt;

    if (androidVersion >= 31) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<void> _checkDetailedPermissions() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    final List<String> missingPermissions = [];

    // Android 权限检查
    final hasAlert = await Permission.notification.request().isGranted;
    if (!hasAlert) {
      missingPermissions.add('通知权限');
    }

    if (missingPermissions.isNotEmpty) {
      final context = MyApp.navigatorKey.currentState?.context;
      if (context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('缺少必要的通知权限'),
            content:
                Text('为了更好的使用体验，请开启以下权限：\n${missingPermissions.join('\n')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('忽略'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  AppSettings.openAppSettings();
                },
                child: const Text('去设置'),
              ),
            ],
          ),
        );
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
        displayOnBackground: true,
        showWhen: true,
        badge: 1,
        payload: {'id': id.toString()},
      );

      final actionButtons = [
        NotificationActionButton(
          key: 'MARK_COMPLETED',
          label: '标记完成',
          actionType: ActionType.SilentAction,
          enabled: true,
        ),
        NotificationActionButton(
          key: 'POSTPONE_1_HOUR',
          label: '推迟1小时',
          actionType: ActionType.SilentAction,
          enabled: true,
        ),
        NotificationActionButton(
          key: 'POSTPONE_1_DAY',
          label: '推迟1天',
          actionType: ActionType.SilentAction,
          enabled: true,
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
      print('��消所有提醒失败: $e');
      rethrow;
    }
  }

  Future<void> updateBadgeCount(int count) async {
    try {
      await AwesomeNotifications().setGlobalBadgeCounter(count);
      print('更新角标数量: $count');
    } catch (e) {
      print('更新角标数量失败: $e');
    }
  }
}
