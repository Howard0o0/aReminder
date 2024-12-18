import 'package:flutter/material.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 添加这一行
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';
import 'add_reminder_screen.dart';
import '../widgets/reminder_details_sheet.dart';
import 'lists_screen.dart';
import 'profile_screen.dart';
import '../services/version_service.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
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
          title: Text('有新版本可更新',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          content: Text(comment), // 使用服务器返回的更新说明
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
    return context.read<AuthProvider>().user?.isVip == false &&
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

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('列表'),
              onPressed: () async {
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
            ),
            middle: const Text('提醒事项'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CupertinoButton(
                //   padding: EdgeInsets.zero,
                //   child: const Icon(CupertinoIcons.share),
                //   onPressed: () {
                //     // TODO: 实现分享功能
                //   },
                // ),
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
                                  builder: (context) => const ProfileScreen(),
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
                        ],
                      ),
                    ),
                    if (_isAddingNewReminder) ...[
                      Container(
                        color: CupertinoColors.white,
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
      return DateFormat('HH:mm').format(date);
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
            onTap: () => provider.toggleComplete(reminder),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: reminder.isCompleted
                      ? CupertinoColors.activeBlue
                      : Color(0xFFD1D1D6),
                  width: 1.5,
                ),
                color: reminder.isCompleted
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.white,
              ),
              child: reminder.isCompleted
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
          subtitle: reminder.dueDate != null
              ? Text(
                  _formatDate(reminder.dueDate),
                  style: TextStyle(
                    fontSize: 15,
                    color: _isOverdue(reminder.dueDate!)
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                )
              : null,
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
