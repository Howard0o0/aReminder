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
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/repeat_type.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void showInstructionDialog(BuildContext context) {
    final pageController = PageController();
    int currentPage = 0;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setState) => CupertinoAlertDialog(
            title: const Text("设置权限(很关键)"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: 400,
                  child: PageView(
                    controller: pageController,
                    onPageChanged: (index) {
                      setState(() => currentPage = index);
                    },
                    children: [
                      // 第一张图 - 通知权限设置
                      Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Text(
                                '华为为例: 设置-应用和服务-应用管理-iReminder-通知管理-提醒服务\n'
                                '请开启以下通知权限:\n'
                                '1. 锁屏通知\n'
                                '2. 横幅通知',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 10),
                              Image.asset(
                                'asset/image/huawei_notification.jpg',
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 第二张图 - 自启动权限设置
                      Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Text(
                                '华为为例: 设置-应用和服务-应用启动管理-iReminder\n'
                                '请开启以下权限:\n'
                                '1. 允许自启动\n'
                                '2. 允许后台活动',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 10),
                              Image.asset(
                                'asset/image/huawei_boot_manager.jpg',
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 自定义指示点
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPage == index
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 添加小红书链接按钮
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    onPressed: () async {
                      final url = 'http://xhslink.com/a/MxvPJFyPWIA2';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '去小红书看详细说明',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () async {
                  print('忽略');
                  Navigator.pop(context);
                },
                child: const Text(
                  '朕知道了',
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
      ),
    );
  }

  Future<void> requestRequiredPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch || true) {
      final permissions = await AwesomeNotifications().checkPermissionList();
      print('原始通知权限状态: $permissions');

      // final context = MyApp.navigatorKey.currentState?.context;
      // if (context != null) {
      //   showInstructionDialog(context);
      // }

      await prefs.setBool('is_first_launch', false);
    }

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
      return;
    }

    await AwesomeNotifications().cancel(reminder.id!);

    // 只创建当前提醒，不再自动调度下一次
    await createReminderNotification(
      id: reminder.id!,
      title: reminder.title,
      body: reminder.notes,
      scheduleTime: reminder.dueDate,
    );

    ApiService.addAppReport(
      'Scheduled a reminder. [reminder: $reminder]'
    );
  }

  // 添加新方法用于处理重复提醒的重新调度
  Future<void> rescheduleRepeatingReminder(Reminder reminder) async {
    if (reminder.repeatType == null || reminder.repeatType == RepeatType.never) {
      return;
    }

    print(
        'rescheduleRepeatingReminder. repeatType: ${reminder.repeatType}, customRepeatDays: ${reminder.customRepeatDays}');
    final nextOccurrence = reminder.repeatType.getNextOccurrence(
      reminder.dueDate!,
      customDays: reminder.customRepeatDays,
    );
    print('nextOccurrence: $nextOccurrence');
    if (nextOccurrence != null) {
      final nextReminder = Reminder(
        id: reminder.id,
        title: reminder.title,
        notes: reminder.notes,
        url: reminder.url,
        dueDate: nextOccurrence,
        isCompleted: false,
        priority: reminder.priority,
        list: reminder.list,
        repeatType: reminder.repeatType,
      );
      
      // 更新数据库中的下一次提醒时间
      await DatabaseService().updateReminder(nextReminder);
      // 调度下一次提醒
      await scheduleReminder(nextReminder);
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

  Future<void> updateBadgeCount(int count) async {
    try {
      await AwesomeNotifications().setGlobalBadgeCounter(count);
      print('更新角标数量: $count');
    } catch (e) {
      print('更新角标数量失败: $e');
    }
  }
}
