import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderDetailsSheet extends StatefulWidget {
  final Reminder reminder;
  final Function(Reminder) onUpdate;

  const ReminderDetailsSheet({
    super.key,
    required this.reminder,
    required this.onUpdate,
  });

  @override
  State<ReminderDetailsSheet> createState() => _ReminderDetailsSheetState();
}

class _ReminderDetailsSheetState extends State<ReminderDetailsSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _urlController;
  bool _hasDate = false;
  bool _hasTime = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _notesController = TextEditingController(text: widget.reminder.notes);
    _urlController = TextEditingController(text: widget.reminder.url);
    if (widget.reminder.dueDate != null) {
      _hasDate = true;
      _selectedDate = widget.reminder.dueDate;
      _hasTime = widget.reminder.dueDate?.hour != 0 ||
          widget.reminder.dueDate?.minute != 0;
      if (_hasTime) {
        _selectedTime = TimeOfDay.fromDateTime(widget.reminder.dueDate!);
      }
    }
    _initializeNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    if (reminder.dueDate == null) return;

    try {
      final notificationService = NotificationService();
      await notificationService.scheduleReminder(reminder);
    } catch (e) {
      print('调度通知失败: $e');
      // 可以在这里添加错误提示
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('通知设置失败'),
            content: const Text('无法设置提醒通知，请检查通知权限'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _save() async {
    DateTime? dueDate;
    if (_hasDate) {
      if (_selectedDate != null) {
        if (_hasTime && _selectedTime != null) {
          dueDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
        } else {
          // 如果只选择了日期，默认设置为当天早上 9 点
          dueDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            9,
            0,
          );
        }
      }
    }

    // 检查时间是否已过
    if (dueDate != null && dueDate.isBefore(DateTime.now())) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('无效的时间'),
            content: const Text('请选择一个未来的时间'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    final updatedReminder = Reminder(
      id: widget.reminder.id,
      title: _titleController.text,
      notes: _notesController.text,
      url: _urlController.text,
      dueDate: dueDate,
      isCompleted: widget.reminder.isCompleted,
      priority: widget.reminder.priority,
      list: widget.reminder.list,
    );

    widget.onUpdate(updatedReminder);
    
    // 先保存提醒事项，再设置通知
    try {
      if (dueDate != null) {
        print('设置通知，时间：$dueDate');
        await _scheduleNotification(updatedReminder);
        print('通知设置成功');
      }
    } catch (e) {
      print('设置通知失败: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('通知设置失败'),
            content: const Text('无法设置提醒通知，请检查通知权限'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            middle: const Text('详细信息'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('完成'),
              onPressed: _save,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: '新提醒事项',
                    padding: const EdgeInsets.all(16),
                  ),
                  CupertinoTextField(
                    controller: _notesController,
                    placeholder: '备注',
                    padding: const EdgeInsets.all(16),
                  ),
                  CupertinoTextField(
                    controller: _urlController,
                    placeholder: 'URL',
                    padding: const EdgeInsets.all(16),
                  ),
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: const Text('日期'),
                        trailing: CupertinoSwitch(
                          value: _hasDate,
                          onChanged: (value) {
                            setState(() {
                              _hasDate = value;
                              if (!value) {
                                _hasTime = false;
                                _selectedDate = null;
                                _selectedTime = null;
                              } else {
                                _selectedDate = DateTime.now();
                              }
                            });
                          },
                        ),
                      ),
                      if (_hasDate)
                        CupertinoListTile(
                          title: const Text('时间'),
                          trailing: CupertinoSwitch(
                            value: _hasTime,
                            onChanged: (value) {
                              setState(() {
                                _hasTime = value;
                                if (value && _selectedTime == null) {
                                  _selectedTime = TimeOfDay.now();
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  if (_hasDate) ...[
                    SizedBox(
                      height: 200,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _selectedDate ?? DateTime.now(),
                        onDateTimeChanged: (date) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                    ),
                  ],
                  if (_hasTime) ...[
                    SizedBox(
                      height: 200,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: _selectedTime != null
                            ? DateTime(
                                2024,
                                1,
                                1,
                                _selectedTime!.hour,
                                _selectedTime!.minute,
                              )
                            : DateTime.now(),
                        onDateTimeChanged: (date) {
                          setState(() =>
                              _selectedTime = TimeOfDay.fromDateTime(date));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
