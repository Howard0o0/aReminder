import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../providers/reminders_provider.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationController {
  /// 当通知被创建时触发
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // 可以在这里添加日志
    print('通知已创建: ${receivedNotification.title}');
  }

  /// 当通知显示时触发
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // 可以在这里添加日志
    print('通知已显示: ${receivedNotification.title}');
    ApiService.addAppReport(
        '通知已显示. [id: ${receivedNotification.id}] [title: ${receivedNotification.title}] [body: ${receivedNotification.body}]');
    final provider = await RemindersProvider.getInstance();
    await provider.updateBadgeCount();
  }

  /// 当用户点击通知时触发
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('onActionReceivedMethod 被调用');
    // 获取 Provider 实例并更新提醒状态
    final provider = await RemindersProvider.getInstance();
    await provider.loadReminders(); // 确保数据已加载

    // 获取提醒的 ID
    final reminderId = receivedAction.id;

    // 检查是否是标记完成按钮
    if (receivedAction.buttonKeyPressed == 'MARK_COMPLETED') {
      print('用户点击了标记完成按钮, 通知ID: ${receivedAction.id}');

      await provider.markReminderAsCompleted(reminderId!);

      // 关闭通知
      await AwesomeNotifications().dismiss(reminderId);
    }

    if (receivedAction.buttonKeyPressed == 'POSTPONE_1_HOUR') {
      print('用户点击了推迟1小时按钮, 通知ID: ${receivedAction.id}');
      // 推迟1小时
      await provider.postponeReminder(reminderId!, const Duration(hours: 1));
    }

    if (receivedAction.buttonKeyPressed == 'POSTPONE_1_DAY') {
      print('用户点击了推迟1天按钮, 通知ID: ${receivedAction.id}');
      // 推迟1天
      await provider.postponeReminder(reminderId!, const Duration(days: 1));
    }
  }

  /// 当通知被用户删除时触发
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('onDismissActionReceivedMethod 被调用');
    print('receivedAction.actionType: ${receivedAction.actionType}');

    final reminderId = receivedAction.id;
    if (reminderId == null) return;

    // 获取初始化完成的 provider 实例
    final provider = await RemindersProvider.getInstance();
    // 设置推迟1小时
    await provider.postponeReminder(reminderId, const Duration(hours: 1));
    print('提醒已被推迟1小时: $reminderId');
  }
}
