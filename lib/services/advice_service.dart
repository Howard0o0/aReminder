import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
class AdviceService {
  static const String baseUrl = 'https://sharpofscience.top/common_service';
  // static const String baseUrl = 'http://192.168.5.11:56666';
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final BuildContext context;

  AdviceService(this.context);

  Future<bool> submitAdvice(String advice) async {
    try {
      // 获取设备信息
      String deviceName = '';
      String os = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
        os = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      // 获取用户状态
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String finalAdvice = advice;

      if (authProvider.isLoggedIn && authProvider.user != null) {
        finalAdvice = '[user email: ${authProvider.user!.userId}] $advice';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/advice/add').replace(queryParameters: {
          'app_key': 'aReminder',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'advice': finalAdvice,
          'device_name': deviceName,
          'os': os,
        }),
      );
      print('Response: ${response.body}');

      final jsonResponse = json.decode(response.body);
      return jsonResponse['success'] ?? false;
    } catch (e) {
      print('Error submitting advice: $e');
      return false;
    }
  }
}
