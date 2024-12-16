import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../providers/reminders_provider.dart';
import '../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddReminderScreen({super.key, this.reminder});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _dueDate;
  int _priority = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title ?? '');
    _notesController = TextEditingController(text: widget.reminder?.notes ?? '');
    _dueDate = widget.reminder?.dueDate;
    _priority = widget.reminder?.priority ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_titleController.text.isEmpty) return;

    final provider = context.read<RemindersProvider>();
    final reminder = Reminder(
      id: widget.reminder?.id,
      title: _titleController.text,
      notes: _notesController.text,
      dueDate: _dueDate,
      priority: _priority,
      isCompleted: widget.reminder?.isCompleted ?? false,
      list: widget.reminder?.list,
    );

    if (widget.reminder == null) {
      provider.addReminder(reminder);
    } else {
      provider.updateReminder(reminder);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.reminder == null ? '新建提醒' : '编辑提醒'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('完成'),
          onPressed: () => _save(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoTextField(
                controller: _titleController,
                placeholder: '标题',
                style: const TextStyle(fontSize: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('详细信息'),
              children: [
                CupertinoListTile(
                  title: const Text('提醒时间'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dueDate == null
                            ? '无'
                            : DateFormat('MM月dd日 HH:mm').format(_dueDate!),
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey),
                      ),
                      const CupertinoListTileChevron(),
                    ],
                  ),
                  onTap: () => _showDatePicker(context),
                ),
                CupertinoListTile(
                  title: const Text('优先级'),
                  trailing: CupertinoSegmentedControl<int>(
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('无'),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('!'),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('!!'),
                      ),
                      3: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('!!!'),
                      ),
                    },
                    groupValue: _priority,
                    onValueChanged: (value) {
                      setState(() => _priority = value);
                    },
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('备注'),
              children: [
                CupertinoTextField(
                  controller: _notesController,
                  placeholder: '添加备注',
                  maxLines: 4,
                  decoration: null,
                ),
              ],
            ),
            if (widget.reminder != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  child: const Text('删除提醒'),
                  onPressed: () {
                    context
                        .read<RemindersProvider>()
                        .deleteReminder(widget.reminder!.id!);
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _dueDate ?? DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() => _dueDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 