import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> generateReport(String report) async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  // 获取设备信息
  String deviceName = '';
  String os = '';
  String version = '';

  final prefs = await SharedPreferences.getInstance();
  final hasAgreedPrivacy = await prefs.getBool('hasAgreedPrivacy') ?? false;

  if (hasAgreedPrivacy) {
    // 获取当前应用版本
    final packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;

    final androidInfo = await deviceInfo.androidInfo;
    deviceName = androidInfo.model;
    os = 'Android ${androidInfo.version.release}';
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
