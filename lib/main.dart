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
import 'providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

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

// 添加前台任务处理函
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
    // print('Foreground service is running...');
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

// 权限请求对话框Widget
class PermissionScreen extends StatefulWidget {
  final Function onPermissionGranted;

  const PermissionScreen({Key? key, required this.onPermissionGranted})
      : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  bool isPrivacyChecked = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));

    // 在下一帧显示对话框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialog();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPermissionDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              content: Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '为确保处于后台运行状态下可正常弹出提醒事项，本应用须使用(自启动)能力，将存在一定频率通过系统发送广播唤醒本应用自启动或关联启动行为，是因实现功能及服务所必要的。',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              sin(_shakeAnimation.value * 3 * 3.14159) *
                                  5 *
                                  (1 - _shakeAnimation.value),
                              0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoCheckbox(
                                  value: isPrivacyChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isPrivacyChecked = value ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(text: '我已阅读'),
                                      TextSpan(
                                        text: '隐私政策',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            launchUrl(Uri.parse(
                                                'https://mirrorcamera.sharpofscience.top/ireminder-privacy.html'));
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text(
                    '拒绝并退出',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    exit(0);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    '同意',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  onPressed: () async {
                    if (!isPrivacyChecked) {
                      // 晃动单选框
                      _animationController.reset();
                      _animationController.forward();
                      return;
                    }
                    Navigator.of(context).pop();

                    // 标记为非首次启动
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isFirstLaunch', false);
                    await prefs.setBool('hasAgreedPrivacy', true);

                    // 通知主函数权限已被授予
                    widget.onPermissionGranted();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 返回一个简单的加载界面
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  final settings = SettingsProvider.instance;
  await settings.init();
  
  // 检查是否是首次启动
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  if (isFirstLaunch) {
    // 显示权限请求屏幕
    runApp(MaterialApp(
      home: PermissionScreen(
        onPermissionGranted: () {
          // 权限授予后初始化应用
          initializeApp();
        },
      ),
    ));
  } else {
    // 如果不是首次启动，直接初始化应用
    initializeApp();
  }
}

void initializeApp() async {
  try {
    // 初始化通知服务
    final notificationService = NotificationService();
    await notificationService.initialize();

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
    final provider = await RemindersProvider.getInstance();
    await provider.loadReminders();

    // 检查逾期未完成的提醒事项
    final now = DateTime.now();
    final overdueReminders = provider.reminders
        .where((reminder) =>
            !reminder.isCompleted &&
            reminder.dueDate != null &&
            !reminder.dueDate!.isAfter(now))
        .toList();

    // 发送逾期通知
    for (var reminder in overdueReminders) {
      print('创建逾期通知: ${reminder.id}');
      await notificationService.createReminderNotification(
        id: reminder.id!,
        title: reminder.title,
        body: reminder.notes,
        isOverdue: true,
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
      await notificationService.scheduleReminder(reminder);
    }

    notificationService.updateBadgeCount(overdueReminders.length);
  } catch (e) {
    print('初始化失败: $e');
  }

  runApp(const MyApp());
}

// 初始化前台任务配置
Future<void> _initForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'iReminder',
      channelName: 'iReminder',
      channelDescription: '保持 iReminder 在前台运行以确保提醒正常触发',
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

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ProductProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => SettingsProvider(),
          ),
        ],
        child: FutureBuilder<RemindersProvider>(
          future: RemindersProvider.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CupertinoApp(
                home: Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return CupertinoApp(
                home: Center(
                  child: Text('错误: ${snapshot.error}'),
                ),
              );
            }

            return ChangeNotifierProvider.value(
              value: snapshot.data!,
              child: CupertinoApp(
                navigatorKey: navigatorKey,
                title: 'iReminder',
                theme: const CupertinoThemeData(
                  primaryColor: CupertinoColors.activeBlue,
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: CupertinoColors.systemBackground,
                  barBackgroundColor: CupertinoColors.systemBackground,
                  textTheme: CupertinoTextThemeData(
                    textStyle: TextStyle(
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HomeScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
