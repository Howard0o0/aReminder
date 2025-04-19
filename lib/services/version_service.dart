import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';

class VersionService {
  static const String baseUrl = 'https://sharpofscience.top/common_service';
  // static const String baseUrl = 'http://192.168.5.11:56666';

  Future<bool> isVersionValid() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/version/min-requirement').replace(
          queryParameters: {
            'app_key': 'iReminder',
          },
        ),
      );

      final jsonResponse = json.decode(response.body);
      final minVersion = jsonResponse['min_version'] as String;

      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      log('当前版本: $currentVersion, 最低版本: $minVersion');

      // 保存下载链接信息供后续使用
      final androidPkgUrl = jsonResponse['android_app_pkg_url'];
      final iosPkgUrl = jsonResponse['ios_app_pkg_url'];

      return _compareVersions(currentVersion, minVersion) >= 0;
    } catch (e) {
      return true;
    }
  }

  int _compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map(int.parse).toList();
    List<int> v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }

  // 检查是否有新版本并返回更新说明
  Future<(bool, String?)> hasNewVersion() async {
    try {
      // 获取系统语言
      final systemLang = PlatformDispatcher.instance.locale.languageCode;
      final lang = systemLang == 'zh' ? 'zh' : 'en';
      print('systemLang: $systemLang, lang: $lang');

      // 获取服务器端最新版本
      final response = await ApiService.getLatestVersion(lang);
      if (!response.success) {
        log('获取最新版本失败: ${response.message}');
        return (false, null);
      }

      final latestVersion = response.data?['latest_version'] as String;
      final comment = response.data?['comment'] as String?;
      // print('comment: $comment');

      // 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      log('当前版本: $currentVersion, 最新版本: $latestVersion');

      // 比较版本号，如���最新版本大于当前版本，则返回 true 和更新说明
      return (_compareVersions(currentVersion, latestVersion) < 0, comment);
    } catch (e) {
      log('检查新版本出错: $e');
      // 如果出现错误，返回 false 以避免错误提示
      return (false, null);
    }
  }
}
