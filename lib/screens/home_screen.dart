import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 添加这一行
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';
import '../widgets/reminder_details_sheet.dart';
import 'lists_screen.dart';
import 'profile_screen.dart';
import '../services/version_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repeat_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin/install_plugin.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/settings_provider.dart';
import 'get_membership_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _newReminderController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAddingNewReminder = false;
  bool _showCompletedItems = false;
  final ValueNotifier<bool> _shouldHighlightInfo = ValueNotifier<bool>(false);
  late AnimationController _animationController;

  static const kMaxFreeReminders = 3;

  // 添加一个 Map 来跟踪每个提醒事项的动画状态
  final Map<int, bool> _animatingItems = {};

  double _downloadProgress = 0.0;
  String _downloadSpeed = '';
  DateTime? _lastProgressUpdate;
  int? _lastReceivedBytes;
  final _speedUpdateInterval =
      const Duration(milliseconds: 500); // 设置更新间隔为500ms
  List<double> _speedBuffer = []; // 用于计算平均速度的缓冲区
  static const int _speedBufferSize = 3; // 平均速度计算使用的样本数

  String _currentListType = 'incomplete'; // 添加这一行

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
    _checkFirstLaunch();

    Future.microtask(() async {
      await NotificationService().requestRequiredPermissions();
      final prefs = await SharedPreferences.getInstance();
      final hasShownInstruction =
          prefs.getBool('has_shown_instruction') ?? false;
      if (!hasShownInstruction) {
        _shouldHighlightInfo.value = true; // 使用 ValueNotifier
      }
    });
    // 加载已有的提醒事项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().loadReminders();
    });
    _checkVersion();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    print('isFirstLaunch: $isFirstLaunch');

    if (isFirstLaunch) {
      // 显示权限提示对话框
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {});
  }

  @override
  void dispose() {
    // 在 dispose 时移除高亮遮罩
    _shouldHighlightInfo.value = false;

    _animationController.dispose();
    print('dispose');

    _newReminderController.dispose();
    _focusNode.dispose();
    _shouldHighlightInfo.dispose(); // 记得释放 ValueNotifier
    super.dispose();
  }

  Future<void> _checkVersion() async {
    final versionService = VersionService();
    final isValid = await versionService.isVersionValid();

    if (!isValid && mounted) {
      _showForceUpdateDialog();
      return;
    }

    final (hasNewVersion, comment) = await versionService.hasNewVersion();
    if (hasNewVersion && mounted && comment != null) {
      _showSoftUpdateDialog(comment);
    }
  }

  void _showForceUpdateDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: CupertinoAlertDialog(
          title: Text("需要更新版本"),
          content: Text("旧版本已不再支持，请升级到新版继续使用"),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                final url = Uri.parse(ApiService.officialWebsite);
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text(
                '去更新',
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
  }

  void _showSoftUpdateDialog(String comment) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: CupertinoAlertDialog(
          title: const Text('有新版本可更新',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          content: Text(comment,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 14)), // 使用服务器返回的更新说明
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '忽略',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final url = Uri.parse('http://areminder.sharpofscience.top/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text('去更新',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemBlue)),
            ),
          ],
        ),
      ),
    );
  }

  bool isNotVipAndTodoRemindersOverflow() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.isVipValid() == false &&
        context.read<RemindersProvider>().incompleteReminders.length >=
            kMaxFreeReminders;
  }

  void _startAddingNewReminder() {
    if (isNotVipAndTodoRemindersOverflow()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('待办提醒事项已满'),
          content: const Text('非Pro用户最多只能保留$kMaxFreeReminders个待办提醒事项.',
              textAlign: TextAlign.left),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text('开通 PRO'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isAddingNewReminder = true;
    });
    // 自动显示键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _saveNewReminder(RemindersProvider provider) async {
    if (_newReminderController.text.isNotEmpty) {
      print('Saving new reminder: ${_newReminderController.text}');
      final reminder = Reminder(
        title: _newReminderController.text,
        isCompleted: false,
        priority: 0,
      );
      await provider.addReminder(reminder);
      print('Reminder saved');
      _newReminderController.clear();
    }
    setState(() {
      _isAddingNewReminder = false;
    });
  }

  // 在CupertinoTextField中添加这个方法处理提交
  void _handleSubmitted(String value, RemindersProvider provider) {
    if (value.isNotEmpty) {
      _saveNewReminder(provider);
    }
  }

  void _showReminderDetails(BuildContext context, Reminder reminder) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ReminderDetailsSheet(
          reminder: reminder,
          onUpdate: (updatedReminder) {
            context.read<RemindersProvider>().updateReminder(updatedReminder);
          },
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    bool isPrivacyChecked = false;
    final GlobalKey checkboxKey = GlobalKey();
    late Animation<double> shakeAnimation;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        // 创建晃动动画
        shakeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticIn,
        ));

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
                        animation: shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              sin(shakeAnimation.value * 3 * 3.14159) *
                                  5 *
                                  (1 - shakeAnimation.value),
                              0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoCheckbox(
                                  key: checkboxKey,
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
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInstruction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_instruction', true);
    _shouldHighlightInfo.value = false; // 使用 ValueNotifier
    NotificationService().showInstructionDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    print('build');

    return Consumer<RemindersProvider>(
      builder: (context, provider, child) {
        // 根据当前列表类型获取对应的提醒事项
        List<Reminder> currentReminders;
        switch (_currentListType) {
          case 'completed':
            currentReminders = _sortReminders(provider.completedReminders);
          case 'scheduled':
            currentReminders =
                _groupScheduledReminders(provider.scheduledReminders);
          case 'incomplete':
          default:
            currentReminders = _sortReminders(provider.incompleteReminders);
        }

        return Stack(
          children: [
            CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                leading: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const ListsScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _currentListType = result;
                      });
                    }
                  },
                  child: const CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: null,
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.left_chevron,
                            size: 17, color: CupertinoColors.black),
                        Text('列表',
                            style: TextStyle(
                                fontSize: 17, color: CupertinoColors.black)),
                      ],
                    ),
                  ),
                ),
                middle: const Text('提醒事项'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAddingNewReminder)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          '完成',
                          style: TextStyle(fontSize: 17),
                        ),
                        onPressed: () => _saveNewReminder(provider),
                      )
                    else ...[
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.info_circle),
                        onPressed: _showInstruction,
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.ellipsis_circle),
                        onPressed: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              actions: [
                                CupertinoActionSheetAction(
                                  child: const Text('个人中心'),
                                  onPressed: () {
                                    Navigator.pop(context); // 关闭弹出菜单
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            const ProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                child: const Text('取消'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              CupertinoSliverRefreshControl(
                                onRefresh: () => provider.loadReminders(),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _buildReminderItem(
                                      context,
                                      currentReminders[index],
                                      provider,
                                    );
                                  },
                                  childCount: currentReminders.length,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(height: 76),
                              ),
                            ],
                          ),
                        ),
                        if (_isAddingNewReminder) ...[
                          Container(
                            color: CupertinoColors.white,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Color(0xFFE5E5EA), width: 0.5),
                                      bottom: BorderSide(
                                          color: Color(0xFFE5E5EA), width: 0.5),
                                    ),
                                  ),
                                  child: CupertinoTextField(
                                    controller: _newReminderController,
                                    focusNode: _focusNode,
                                    placeholder: '添加备注',
                                    placeholderStyle: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 17,
                                    ),
                                    style: const TextStyle(fontSize: 17),
                                    decoration: null,
                                    maxLines:
                                        Provider.of<SettingsProvider>(context)
                                                .multiLineReminderContent
                                            ? null
                                            : 1,
                                    minLines: 1,
                                    onSubmitted: (value) =>
                                        _handleSubmitted(value, provider),
                                  ),
                                ),
                                Container(
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFE5E5EA), width: 0.5),
                                    ),
                                  ),
                                  // TODO
                                  // child: Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceAround,
                                  //   children: [
                                  //     _buildToolbarButton(CupertinoIcons.calendar),
                                  //     _buildToolbarButton(CupertinoIcons.bell),
                                  //     _buildToolbarButton(CupertinoIcons.tag),
                                  //     _buildToolbarButton(CupertinoIcons.flag),
                                  //     _buildToolbarButton(CupertinoIcons.camera),
                                  //   ],
                                  // ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!_isAddingNewReminder)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: CupertinoColors.systemBackground,
                        child: SafeArea(
                          top: false,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(10),
                              child: const Text(
                                '新提醒事项',
                                style: TextStyle(fontSize: 17),
                              ),
                              onPressed: _startAddingNewReminder,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _shouldHighlightInfo,
              builder: (context, shouldHighlight, child) {
                if (!shouldHighlight) return const SizedBox.shrink();

                // 使用 MediaQuery 获取状态栏高度和屏幕尺寸
                final mediaQuery = MediaQuery.of(context);
                final statusBarHeight = mediaQuery.padding.top;
                final navBarHeight = 44.0; // CupertinoNavigationBar 的标准高度

                // 计算 info button 的位置
                final buttonSize = 44.0; // CupertinoButton 的标准尺寸
                final screenWidth = mediaQuery.size.width;
                final buttonPosition =
                    screenWidth - buttonSize - 44.0; // 44.0 是右边距

                return GestureDetector(
                  onTap: _showInstruction,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.7),
                    child: Stack(
                      children: [
                        // 高亮圆圈
                        Positioned(
                          // 计算垂直中心点：状态栏高度 + 导航栏中心点位置
                          top:
                              statusBarHeight + (navBarHeight - buttonSize) / 2,
                          // 计算水平中心点：按钮位置 + 按钮尺寸的一半 - 圆圈尺寸的一半
                          left: buttonPosition +
                              (buttonSize / 2) -
                              ((buttonSize + 22) / 2),
                          child: Container(
                            width: buttonSize + 22, // 圆圈直径
                            height: buttonSize + 22, // 圆圈直径
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.activeBlue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // 提示文本
                        Positioned(
                          top: statusBarHeight + navBarHeight + 20,
                          left: 0,
                          right: 0,
                          child: const Text(
                            '首次使用请阅读说明',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == dayBeforeYesterday) {
      return '前天 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MM/dd/yyyy HH:mm').format(date);
    }
  }

  Widget _buildReminderItem(
    BuildContext context,
    Reminder reminder,
    RemindersProvider provider,
  ) {
    // 如果是分隔符（priority == -1），使用不同的样式
    if (reminder.priority == -1) {
      return Container(
        key: ValueKey('header_${reminder.id}'),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          reminder.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          maxLines:
              Provider.of<SettingsProvider>(context).multiLineReminderContent
                  ? null
                  : 1,
          overflow:
              Provider.of<SettingsProvider>(context).multiLineReminderContent
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
        ),
      );
    }

    // 构建副标题组件
    Widget? subtitle;
    if (reminder.dueDate != null) {
      final hasRepeat = reminder.repeatType != null &&
          reminder.repeatType != RepeatType.never;
      final textColor = _isOverdue(reminder.dueDate!)
          ? CupertinoColors.systemRed
          : CupertinoColors.systemGrey;

      subtitle = Row(
        key: ValueKey('subtitle_${reminder.id}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(reminder.dueDate),
            style: TextStyle(
              fontSize: 15,
              color: textColor,
            ),
          ),
          if (hasRepeat) ...[
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.repeat,
              size: 14,
              color: CupertinoColors.systemBlue,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                reminder.repeatType
                    .getLocalizedName(customDays: reminder.customRepeatDays),
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );
    }

    // 原有的提醒项渲染逻辑
    return Dismissible(
      key: ValueKey('dismissible_${reminder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('删除提醒'),
                content: const Text('确定要删除这个提醒吗？'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('删除'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        provider.deleteReminder(reminder.id!);
      },
      child: GestureDetector(
        onTap: () => _showReminderDetails(context, reminder),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 左侧的复选框
                GestureDetector(
                  onTap: () {
                    if (_animatingItems[reminder.id] == true) return;

                    setState(() {
                      _animatingItems[reminder.id!] = true;
                    });

                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        provider.toggleComplete(reminder);
                        setState(() {
                          _animatingItems[reminder.id!] = false;
                        });
                      }
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _animatingItems[reminder.id] == true ||
                                reminder.isCompleted
                            ? CupertinoColors.activeBlue
                            : Color(0xFFD1D1D6),
                        width: 1.5,
                      ),
                      color: _animatingItems[reminder.id] == true ||
                              reminder.isCompleted
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.white,
                    ),
                    child: (_animatingItems[reminder.id] == true ||
                            reminder.isCompleted)
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            size: 14,
                            color: CupertinoColors.white,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                // 中间的标题和副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 17,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: reminder.isCompleted
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.black,
                        ),
                        maxLines: Provider.of<SettingsProvider>(context)
                                .multiLineReminderContent
                            ? null
                            : 1,
                        overflow: Provider.of<SettingsProvider>(context)
                                .multiLineReminderContent
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey3,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Icon(
        icon,
        color: CupertinoColors.activeBlue,
        size: 24,
      ),
      onPressed: () {
        // TODO: 实现相应功能
      },
    );
  }

  // 添加一个辅助方法来判断是否逾期
  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  // 添加一个辅助方法来排序提醒事项
  List<Reminder> _sortReminders(List<Reminder> reminders) {
    // 复制列表以避免修改原始数据
    final List<Reminder> sortedList = List.from(reminders);

    // 将提醒事项分为两组：没有到期时间的和有到期时间的
    final List<Reminder> withoutDueDate =
        sortedList.where((r) => r.dueDate == null).toList();
    final List<Reminder> withDueDate =
        sortedList.where((r) => r.dueDate != null).toList();

    // 对没有到期时间的提醒事项按创建时间排序（假设id代表创建顺序）
    withoutDueDate.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    // 对有到期时间的提醒事项按到期时间升序排序
    withDueDate.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // 合并两个列表，没有到期时间的在前面
    return [...withoutDueDate, ...withDueDate];
  }

  String _formatSpeed(double speedInBytes) {
    if (speedInBytes < 1024) {
      return '${speedInBytes.toStringAsFixed(1)} B/s';
    } else if (speedInBytes < 1024 * 1024) {
      return '${(speedInBytes / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedInBytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  // 添加分组逻辑的辅助方法
  List<Reminder> _groupScheduledReminders(List<Reminder> reminders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 首先对列表应用我们的排序逻辑
    List<Reminder> sortedReminders = _sortReminders(reminders);

    // 添加日期分隔符
    List<Reminder> groupedReminders = [];
    DateTime? lastDate;

    // 首先添加没有到期时间的提醒事项（如果有的话）
    for (var reminder in sortedReminders.where((r) => r.dueDate == null)) {
      groupedReminders.add(reminder);
    }

    // 如果有没有到期时间的提醒事项和有到期时间的提醒事项，添加一个分隔符
    if (groupedReminders.isNotEmpty &&
        sortedReminders.any((r) => r.dueDate != null)) {
      final headerReminder = Reminder(
        id: -1, // 使用固定ID
        title: '计划',
        isCompleted: false,
        priority: -1, // 用于标识这是一个分隔符
      );
      groupedReminders.add(headerReminder);
    }

    // 然后处理有到期时间的提醒事项
    for (var reminder in sortedReminders.where((r) => r.dueDate != null)) {
      final reminderDate = DateTime(
        reminder.dueDate!.year,
        reminder.dueDate!.month,
        reminder.dueDate!.day,
      );

      if (lastDate == null || reminderDate != lastDate) {
        final headerReminder = Reminder(
          id: -reminderDate.millisecondsSinceEpoch, // 使用负的时间戳
          title: _getDateHeader(reminderDate, today),
          isCompleted: false,
          priority: -1, // 用于标识这是一个分隔符
        );
        groupedReminders.add(headerReminder);
        lastDate = reminderDate;
      }
      groupedReminders.add(reminder);
    }

    return groupedReminders;
  }

  String _getDateHeader(DateTime date, DateTime today) {
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) {
      return '今天';
    } else if (date == tomorrow) {
      return '明天';
    } else if (date.year == today.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }
}
