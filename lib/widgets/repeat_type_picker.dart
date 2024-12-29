import 'package:flutter/cupertino.dart';
import '../models/repeat_type.dart';

class RepeatTypePicker extends StatelessWidget {
  final RepeatType initialValue;

  const RepeatTypePicker({
    super.key,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('重复'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: CupertinoListSection.insetGrouped(
          children: RepeatType.values
              .map(
                (type) => CupertinoListTile(
                  title: Text(type.localizedName),
                  trailing: type == initialValue
                      ? const Icon(CupertinoIcons.check_mark,
                          color: CupertinoColors.activeBlue)
                      : null,
                  onTap: () => Navigator.pop(context, type),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
