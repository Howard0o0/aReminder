import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationController {
  /// 当通知被创建时调用
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    print('通知已创建:');
    print('ID: ${receivedNotification.id}');
    print('标题: ${receivedNotification.title}');
    print('内容: ${receivedNotification.body}');
  }

  /// 当通知显示时调用
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    print('通知已显示:');
    print('ID: ${receivedNotification.id}');
    print('标题: ${receivedNotification.title}');
    print('内容: ${receivedNotification.body}');
    print('显示时间: ${DateTime.now()}');
  }

  /// 当用户点击通知时调用
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('通知被点击:');
    print('ID: ${receivedAction.id}');
    print('标题: ${receivedAction.title}');
    print('内容: ${receivedAction.body}');
    print('点击时间: ${DateTime.now()}');
  }

  /// 当通知被关闭时调用
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('通知被关闭:');
    print('ID: ${receivedAction.id}');
    print('标题: ${receivedAction.title}');
    print('内容: ${receivedAction.body}');
    print('关闭时间: ${DateTime.now()}');
  }
} 