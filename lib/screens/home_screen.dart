import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';
import 'add_reminder_screen.dart';
import '../widgets/reminder_details_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _newReminderController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAddingNewReminder = false;

  @override
  void initState() {
    super.initState();
    // 加载已有的提醒事项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().loadReminders();
    });
  }

  @override
  void dispose() {
    _newReminderController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAddingNewReminder() {
    setState(() {
      _isAddingNewReminder = true;
    });
    // 自动显示���盘
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
              onPressed: () {
                // TODO: 返回列表页面
              },
            ),
            middle: const Text('提醒事项'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.share),
                  onPressed: () {
                    // TODO: 实现分享功能
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis_circle),
                  onPressed: () {
                    // TODO: 显示更多选项
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
                              (context, index) => _buildReminderItem(
                                context,
                                provider.reminders[index],
                                provider,
                              ),
                              childCount: provider.reminders.length,
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
                                  bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
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
                                onSubmitted: (value) => _handleSubmitted(value, provider),
                              ),
                            ),
                            Container(
                              height: 44,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildToolbarButton(CupertinoIcons.calendar),
                                  _buildToolbarButton(CupertinoIcons.bell),
                                  _buildToolbarButton(CupertinoIcons.tag),
                                  _buildToolbarButton(CupertinoIcons.flag),
                                  _buildToolbarButton(CupertinoIcons.camera),
                                ],
                              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return Container(
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
                style: const TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemRed,
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
}
