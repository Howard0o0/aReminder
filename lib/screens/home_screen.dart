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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _newReminderController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAddingNewReminder = false;
  bool _showCompletedItems = false;
  bool _shouldHighlightInfo = false;

  // 添加一个 Map 来跟踪每个提醒事项的动画状态
  final Map<int, bool> _animatingItems = {};

  final GlobalKey _infoButtonKey = GlobalKey(); // 添加这一行来获取按钮位置

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await NotificationService().requestRequiredPermissions();
      // 检查是否是首次启动
      final prefs = await SharedPreferences.getInstance();
      final hasShownInstruction =
          prefs.getBool('has_shown_instruction') ?? false;
      if (!hasShownInstruction) {
        setState(() {
          _shouldHighlightInfo = true;
        });
      }
    });
    // 加载已有的提醒事项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().loadReminders();
    });
    _checkVersion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {});
  }

  @override
  void dispose() {
    _newReminderController.dispose();
    _focusNode.dispose();
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
                // TODO
                final url = Uri.parse(ApiService.officialWebsite);
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text(
                '立即更新',
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

  bool isNotVipAndTodoRemindersOverflow() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.isVipValid() == false &&
        context.read<RemindersProvider>().incompleteReminders.length >= 10;
  }

  void _startAddingNewReminder() {
    if (isNotVipAndTodoRemindersOverflow()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('待办提醒事项已满'),
          content: const Text('非会员最多只能创建10个待办提醒事项\n请将一些待办事项删除或者标记为已完成~'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('我知道了'),
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

  void _showInstruction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_instruction', true);
    setState(() {
      _shouldHighlightInfo = false;
    });
    NotificationService().showInstructionDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, provider, child) {
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
                        _showCompletedItems = result;
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
                        key: _infoButtonKey, // 添加 key
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
                                    final items = _showCompletedItems
                                        ? provider.completedReminders
                                        : provider.incompleteReminders;
                                    return _buildReminderItem(
                                      context,
                                      items[index],
                                      provider,
                                    );
                                  },
                                  childCount: _showCompletedItems
                                      ? provider.completedReminders.length
                                      : provider.incompleteReminders.length,
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
                                    placeholderStyle: TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 17,
                                    ),
                                    style: TextStyle(fontSize: 17),
                                    decoration: null,
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
            if (_shouldHighlightInfo)
              GestureDetector(
                onTap: _showInstruction,
                child: CustomPaint(
                  painter: HighlightPainter(_infoButtonKey),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 100),
                        Text(
                          '首次使用请阅读说明',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    // 构建副标题组件
    Widget? subtitle;
    if (reminder.dueDate != null) {
      final hasRepeat = reminder.repeatType != null &&
          reminder.repeatType != RepeatType.never;
      final textColor = _isOverdue(reminder.dueDate!)
          ? CupertinoColors.systemRed
          : CupertinoColors.systemGrey;

      subtitle = Row(
        children: [
          Text(
            _formatDate(reminder.dueDate),
            style: TextStyle(
              fontSize: 15,
              color: textColor,
            ),
          ),
          if (hasRepeat) ...[
            const SizedBox(width: 4), // 添加小间距
            Icon(
              CupertinoIcons.repeat,
              size: 14,
              color: CupertinoColors.systemBlue,
            ),
            const SizedBox(width: 2), // 添加小间距
            Text(
              reminder.repeatType!.localizedName,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ],
      );
    }

    return Dismissible(
      key: Key(reminder.id.toString()),
      direction: DismissDirection.endToStart, // 只允许从右向左滑动
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
        // 显示确认对话框
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
        // 删除提醒
        provider.deleteReminder(reminder.id!);
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
        ),
        child: CupertinoListTile(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () {
              // 如果已经在动画中，直接返回
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
                color:
                    _animatingItems[reminder.id] == true || reminder.isCompleted
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.white,
              ),
              child:
                  (_animatingItems[reminder.id] == true || reminder.isCompleted)
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          size: 14,
                          color: CupertinoColors.white,
                        )
                      : null,
            ),
          ),
          title: Text(
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
          ),
          subtitle: subtitle,
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.systemGrey3,
            size: 20,
          ),
          onTap: () => _showReminderDetails(context, reminder),
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
}

// 添加自定义画布类来绘制遮罩和高亮效果
class HighlightPainter extends CustomPainter {
  final GlobalKey targetKey;

  HighlightPainter(this.targetKey);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 获取目标按钮的位置和大小
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final center = Offset(
      position.dx + buttonSize.width / 2,
      position.dy + buttonSize.height / 2,
    );
    final radius = buttonSize.width * 0.8;

    // 创建一个路径来绘制遮罩
    final path = Path()
      ..addRect(Offset.zero & size) // 添加整个屏幕大小的矩形
      ..addOval(Rect.fromCircle(center: center, radius: radius)) // 添加圆形
      ..fillType = PathFillType.evenOdd; // 使用 evenOdd 规则，这样圆形区域会被"挖空"

    // 绘制遮罩
    canvas.drawPath(path, paint);

    // 绘制高亮边框
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = CupertinoColors.activeBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
