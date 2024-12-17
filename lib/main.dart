import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/reminders_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'controllers/notification_controller.dart';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';

// 后台任务回调函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  // 确保在回调中初始化必要的服务
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask((task, inputData) async {
    try {
      // 确保通知服务被初始化
      await NotificationService().initialize();

      if (task == 'showReminderNotification') {
        final reminderJson = inputData?['reminder'];
        if (reminderJson != null) {
          final reminderData = jsonDecode(reminderJson);

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: reminderData['id'],
              channelKey: 'scheduled_channel',
              title: reminderData['title'],
              body: reminderData['notes'] ?? '',
              category: NotificationCategory.Alarm,
              wakeUpScreen: true,
              fullScreenIntent: true,
              autoDismissible: false,
              locked: true,
              criticalAlert: true,
              notificationLayout: NotificationLayout.Default,
            ),
          );

          print('提醒通知已发送');
        }
      }
      return true;
    } catch (e) {
      print('执行提醒任务失败: $e');
      return false;
    }
  });
}

// 添加前台任务处理函数
@pragma('vm:entry-point')
void startForegroundTask() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

// 创建前台任务处理器
class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('前台任务启动');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    print('Foreground service is running...');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('前台任务销毁');
    await FlutterForegroundTask.restartService();
  }

  @override
  void onReceiveData(Object data) {
    print('接收到数据: $data');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化前台任务配置
  await _initForegroundTask();
  await FlutterForegroundTask.startService(
    notificationTitle: 'aReminder',
    notificationText: '保持 aReminder 在前台运行, 确保提醒正常触发',
    callback: startForegroundTask,
  );

  try {
    // 初始化通知服务
    await NotificationService().initialize();

    // 设置通知监听
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );

    // 应用启动时，扫描所有提醒事项
    final provider = RemindersProvider();
    await provider.loadReminders();

    // 检查逾期未完成的提醒事项
    final now = DateTime.now();
    final overdueReminders = provider.reminders
        .where((reminder) =>
            !reminder.isCompleted &&
            reminder.dueDate != null &&
            reminder.dueDate!.isBefore(now))
        .toList();

    // 发送逾期通知
    for (var reminder in overdueReminders) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.id!,
          channelKey: 'scheduled_channel',
          title: '逾期提醒: ${reminder.title}',
          body: '该提醒事项已逾期',
          category: NotificationCategory.Alarm,
          locked: true,
          autoDismissible: false,
        ),
      );
    }

    // 重新调度未来的提醒事项
    final futureReminders = provider.reminders
        .where((reminder) =>
            !reminder.isCompleted &&
            reminder.dueDate != null &&
            reminder.dueDate!.isAfter(now))
        .toList();

    for (var reminder in futureReminders) {
      await NotificationService().scheduleReminder(reminder);
    }
  } catch (e) {
    print('初始化失败: $e');
  }

  runApp(const MyApp());
}

// 初始化前台任务配置
Future<void> _initForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'aReminder',
      channelName: 'aReminder',
      channelDescription: '保持 aReminder 在前台运行以确保提醒正常触发',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      enableVibration: false,
      playSound: false,
      showWhen: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: true,
      allowWifiLock: true,
      eventAction: ForegroundTaskEventAction.repeat(5000), // 使用 repeat
    ),
  );

  // 请求忽略电池优化
  await _requestBatteryOptimization();
}

// 请求忽略电池优化
Future<void> _requestBatteryOptimization() async {
  if (Platform.isAndroid) {
    final bool? isIgnoringBatteryOptimizations =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    if (isIgnoringBatteryOptimizations == false) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      // 包装整个应用
      child: ChangeNotifierProvider(
        create: (_) => RemindersProvider(),
        child: const CupertinoApp(
          title: 'iReminder',
          theme: CupertinoThemeData(
            primaryColor: CupertinoColors.activeBlue,
          ),
          home: HomeScreen(),
        ),
      ),
    );
  }
}
