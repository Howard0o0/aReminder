import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSaveStrategyPicker(
    BuildContext context,
    PhotoSaveStrategy currentStrategy,
    Function(PhotoSaveStrategy) onChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(l10n.photoSaveStrategy),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: currentStrategy == PhotoSaveStrategy.appOnly,
            onPressed: () {
              onChanged(PhotoSaveStrategy.appOnly);
              Navigator.pop(context);
            },
            child: Text(
              l10n.saveToAppOnly,
              style: TextStyle(
                color: currentStrategy == PhotoSaveStrategy.appOnly
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.black,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: currentStrategy == PhotoSaveStrategy.both,
            onPressed: () {
              onChanged(PhotoSaveStrategy.both);
              Navigator.pop(context);
            },
            child: Text(
              l10n.saveToAppAndGallery,
              style: TextStyle(
                color: currentStrategy == PhotoSaveStrategy.both
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.black,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            l10n.cancel,
            style: TextStyle(color: CupertinoColors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Widget? customIcon,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            customIcon ??
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: CupertinoColors.black,
                    size: 23,
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: CupertinoColors.systemGrey3,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: CupertinoColors.systemGrey5,
      indent: 54,
      endIndent: 16,
    );
  }

  Future<void> _showNullTimeAsNowPicker(BuildContext context) async {
    final settings = SettingsProvider.instance;

    if (!settings.isInitialized) {
      await settings.init();
    }

    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: const Text('是否将无时间视为立马提醒？'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('否'),
              onPressed: () async {
                await settings.setNullTimeAsNow(false);
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('是'),
              onPressed: () async {
                await settings.setNullTimeAsNow(true);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          l10n.settings,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: null,
                        customIcon: Container(
                          width: 29,
                          height: 29,
                          child: const Icon(
                            CupertinoIcons.time,
                            size: 30,
                            color: CupertinoColors.systemGrey3,
                          ),
                        ),
                        title: '无时间视为立即提醒',
                        trailing: CupertinoSwitch(
                          value: settings.nullTimeAsNow,
                          onChanged: (bool value) {
                            settings.setNullTimeAsNow(value);
                          },
                        ),
                        onTap: null,
                      ),
                      _buildMenuItem(
                        icon: null,
                        customIcon: Container(
                          width: 29,
                          height: 29,
                          child: const Icon(
                            CupertinoIcons.text_aligncenter,
                            size: 30,
                            color: CupertinoColors.systemGrey3,
                          ),
                        ),
                        title: '多行显示提醒内容',
                        trailing: CupertinoSwitch(
                          value: settings.multiLineReminderContent,
                          onChanged: (bool value) {
                            settings.setMultiLineReminderContent(value);
                          },
                        ),
                        onTap: null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
