import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> generateReport(String report) async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  // 获取设备信息
  String deviceName = '';
  String os = '';
  String version = '';

  // 获取当前应用版本
  final packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;


  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceName = androidInfo.model;
    os = 'Android ${androidInfo.version.release}';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceName = iosInfo.name;
    os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
  }

  String finalReport = '[$version] [os: $os] [device: $deviceName] $report';

  // 使用 navigatorKey 获取全局 context
  final context = MyApp.navigatorKey.currentContext;
  if (context != null) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final userEmail = authProvider.user!.userId;
      final isVip = authProvider.user!.isVipValid;
      finalReport = '[user_id: $userEmail] [isVip: $isVip] $finalReport';
    }
  }

  return finalReport;
}
