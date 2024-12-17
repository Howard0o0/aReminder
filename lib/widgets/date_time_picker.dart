import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime?) onDateTimeChanged;

  const DateTimePicker({
    super.key,
    this.initialDate,
    required this.onDateTimeChanged,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  bool _isDateEnabled = false;
  bool _isTimeEnabled = false;
  bool _isDatePickerVisible = false;
  bool _isTimePickerVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
      _selectedTime = widget.initialDate;
      _isDateEnabled = true;
      _isTimeEnabled = true;
    }
  }

  void _updateDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      widget.onDateTimeChanged(dateTime);
    } else {
      widget.onDateTimeChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoListSection.insetGrouped(
          children: [
            // 日期选择
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isDatePickerVisible = !_isDatePickerVisible;
                    _isTimePickerVisible = false;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/calendar_icon.png', // 需要添加日历图标资源
                        width: 28,
                        height: 28,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '日期',
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.label,
                              ),
                            ),
                            if (_selectedDate != null)
                              Text(
                                '${DateFormat('yyyy年MM月d日').format(_selectedDate!)} ${_getDayOfWeek(_selectedDate!)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _isDateEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isDateEnabled = value;
                            if (!value) {
                              _selectedDate = null;
                              _isDatePickerVisible = false;
                            } else {
                              _selectedDate = DateTime.now();
                              _isDatePickerVisible = true;
                              _isTimePickerVisible = false;
                            }
                            _updateDateTime();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isDatePickerVisible && _isDateEnabled)
              Container(
                height: 300,
                color: CupertinoColors.systemBackground,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月')
                                .format(_selectedDate ?? DateTime.now()),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.left_chevron),
                                onPressed: () {
                                  // 上个月
                                },
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.right_chevron),
                                onPressed: () {
                                  // 下个月
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _selectedDate ?? DateTime.now(),
                        minimumDate: DateTime.now(),
                        onDateTimeChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                            _updateDateTime();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 时间选择
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isTimePickerVisible = !_isTimePickerVisible;
                    _isDatePickerVisible = false;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/clock_icon.png', // 需要添加时钟图标资源
                        width: 28,
                        height: 28,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '时间',
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.label,
                              ),
                            ),
                            if (_selectedTime != null)
                              Text(
                                DateFormat('HH:mm').format(_selectedTime!),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _isTimeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isTimeEnabled = value;
                            if (!value) {
                              _selectedTime = null;
                              _isTimePickerVisible = false;
                            } else {
                              _selectedTime = DateTime.now();
                              _isTimePickerVisible = true;
                              _isDatePickerVisible = false;
                            }
                            _updateDateTime();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isTimePickerVisible && _isTimeEnabled)
              Container(
                height: 200,
                color: CupertinoColors.systemBackground,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: _selectedTime ?? DateTime.now(),
                  onDateTimeChanged: (time) {
                    setState(() {
                      _selectedTime = time;
                      _updateDateTime();
                    });
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getDayOfWeek(DateTime date) {
    final weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[date.weekday % 7];
  }
}
