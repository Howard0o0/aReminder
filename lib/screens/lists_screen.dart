import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('列表'),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildListTile(
                  context,
                  '待办',
                  provider.incompleteReminders.length,
                  false,
                ),
                _buildListTile(
                  context,
                  '已完成',
                  provider.completedReminders.length,
                  true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    int count,
    bool showCompleted,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, showCompleted);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17),
            ),
            const Spacer(),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 17,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.right_chevron,
              color: CupertinoColors.systemGrey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
