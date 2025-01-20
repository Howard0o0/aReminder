import 'package:flutter/cupertino.dart';
import '../models/repeat_type.dart';

class RepeatTypePicker extends StatelessWidget {
  final RepeatType selectedType;
  final Function(RepeatType, int?) onTypeSelected;

  const RepeatTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  void _showCustomDaysDialog(BuildContext context) {
    int days = 1;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
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
                      onTypeSelected(RepeatType.custom, days);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: 0,
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    days = selectedItem + 1;
                  },
                  children: List<Widget>.generate(365, (int index) {
                    return Center(
                      child: Text(
                        '${index + 1}天',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  title: Text(type.getLocalizedName()),
                  trailing: type == selectedType
                      ? const Icon(CupertinoIcons.check_mark,
                          color: CupertinoColors.activeBlue)
                      : null,
                  onTap: () {
                    if (type == RepeatType.custom) {
                      _showCustomDaysDialog(context);
                    } else {
                      onTypeSelected(type, null);
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
