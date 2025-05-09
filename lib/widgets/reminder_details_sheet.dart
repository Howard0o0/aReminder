import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../models/reminder.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/repeat_type.dart';
import 'repeat_type_picker.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

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
  bool _isDatePickerVisible = false;
  bool _isTimePickerVisible = false;
  late RepeatType _repeatType;
  int? _customRepeatDays;

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
    _repeatType = widget.reminder.repeatType;
    _customRepeatDays = widget.reminder.customRepeatDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
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

    final updatedReminder = Reminder(
      id: widget.reminder.id,
      title: _titleController.text,
      notes: _notesController.text,
      url: _urlController.text,
      dueDate: dueDate,
      isCompleted: widget.reminder.isCompleted,
      priority: widget.reminder.priority,
      list: widget.reminder.list,
      repeatType: _repeatType,
      customRepeatDays: _customRepeatDays,
    );

    print('pre-update reminder: $updatedReminder');
    widget.onUpdate(updatedReminder);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
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
                    maxLines: Provider.of<SettingsProvider>(context)
                            .multiLineReminderContent
                        ? null
                        : 1,
                    minLines: 1,
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
                      Container(
                        color: CupertinoColors.white,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isDatePickerVisible = !_isDatePickerVisible;
                              if (_isDatePickerVisible) {
                                _selectedDate = DateTime.now();
                                _isTimePickerVisible = false;
                              }
                            });
                          },
                          child: CupertinoListTile(
                            title: const Text('日期'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasDate)
                                  Text(
                                    '${_selectedDate?.year}年${_selectedDate?.month}月${_selectedDate?.day}日',
                                    style: const TextStyle(
                                        color: CupertinoColors.systemBlue),
                                  ),
                                const SizedBox(width: 8),
                                CupertinoSwitch(
                                  value: _hasDate,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasDate = value;
                                      if (!value) {
                                        _hasTime = false;
                                        _selectedDate = null;
                                        _selectedTime = null;
                                        _isDatePickerVisible = false;
                                        _isTimePickerVisible = false;
                                      } else {
                                        _selectedDate = DateTime.now();
                                        _isDatePickerVisible = true;
                                        _isTimePickerVisible = false;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_hasDate)
                        Container(
                          color: CupertinoColors.white,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _isTimePickerVisible = !_isTimePickerVisible;
                                if (_isTimePickerVisible) {
                                  _selectedTime = TimeOfDay.now();
                                  if (_selectedDate != null) {
                                    _selectedDate = DateTime(
                                      _selectedDate!.year,
                                      _selectedDate!.month,
                                      _selectedDate!.day,
                                      _selectedTime!.hour,
                                      _selectedTime!.minute,
                                    );
                                  }
                                  _isDatePickerVisible = false;
                                }
                              });
                            },
                            child: CupertinoListTile(
                              title: const Text('时间'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasTime)
                                    Text(
                                      '${_selectedTime?.hour.toString().padLeft(2, '0')}:${_selectedTime?.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          color: CupertinoColors.systemBlue),
                                    ),
                                  const SizedBox(width: 8),
                                  CupertinoSwitch(
                                    value: _hasTime,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasTime = value;
                                        if (value) {
                                          _selectedTime = TimeOfDay.now();
                                          _isTimePickerVisible = true;
                                          _isDatePickerVisible = false;
                                        } else {
                                          _selectedTime = null;
                                          _isTimePickerVisible = false;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_hasDate)
                        Container(
                          color: CupertinoColors.white,
                          child: CupertinoListTile(
                            title: const Text('重复'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _repeatType.getLocalizedName(
                                      customDays: _customRepeatDays),
                                  style: const TextStyle(
                                      color: CupertinoColors.systemBlue),
                                ),
                                const CupertinoListTileChevron(),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => RepeatTypePicker(
                                    selectedType: _repeatType,
                                    onTypeSelected: (type, customDays) {
                                      setState(() {
                                        _repeatType = type;
                                        _customRepeatDays = customDays;
                                      });
                                    },
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _repeatType = result;
                                });
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                  if (_hasDate && _isDatePickerVisible)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoDatePicker(
                        key: const ValueKey('date_picker'),
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime:
                            _selectedDate?.isBefore(DateTime.now()) ?? true
                                ? DateTime.now()
                                : _selectedDate!,
                        minimumDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                        onDateTimeChanged: (DateTime date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                    ),
                  if (_hasTime && _isTimePickerVisible)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoDatePicker(
                        key: const ValueKey('time_picker'),
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        initialDateTime: _selectedDate ?? DateTime.now(),
                        onDateTimeChanged: (DateTime date) {
                          setState(() {
                            _selectedTime = TimeOfDay(
                              hour: date.hour,
                              minute: date.minute,
                            );
                            if (_selectedDate != null) {
                              _selectedDate = DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                                date.hour,
                                date.minute,
                              );
                            }
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
