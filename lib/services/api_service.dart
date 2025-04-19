import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/error_codes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/misc.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorCode;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.errorCode,
    this.message,
  });
}

class OrdersResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<Order> orders;

  OrdersResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.orders,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      orders: (json['orders'] as List)
          .map((order) => Order.fromJson(order))
          .toList(),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://sharpofscience.top/common_service';
  // static const String baseUrl = 'http://sharpofscience.top:30012';
  // static const String baseUrl = 'http://192.168.5.11:56666';
  static const String appKey = 'iReminder';

  static const String officialWebsite = 'http://areminder.sharpofscience.top/';

  // 处理 API 响应
  static ApiResponse<T> _handleResponse<T>(http.Response response,
      [T Function(Map<String, dynamic>)? parser]) {
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      print('status code: ${response.statusCode}');
      print('body: $body');
      return ApiResponse(
        success: true,
        data: parser != null ? parser(body) : body as T?,
      );
    }

    // 处理错误响应
    String? errorCode;
    String? message;

    if (body['detail'] is Map) {
      final detail = body['detail'] as Map<String, dynamic>;
      errorCode = detail['errcode'];
      message = detail['message'];
    }

    return ApiResponse(
      success: false,
      errorCode: errorCode ?? ErrorCode.unknownError,
      message: message ?? '未知错误',
    );
  }

  // 发送验证码
  static Future<ApiResponse<void>> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/send-code').replace(
          queryParameters: {
            'app_key': appKey,
            'email': email,
          },
        ),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 验证邮箱
  static Future<ApiResponse<Map<String, dynamic>>> verifyEmail(
      String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify-email').replace(
          queryParameters: {
            'app_key': appKey,
            'email': email,
            'code': code,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 获取会员状态
  static Future<ApiResponse<Map<String, dynamic>>> getMembershipStatus(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/membership/status').replace(
          queryParameters: {
            'app_key': appKey,
            'user_id': userId,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  static Future<ApiResponse> claimMembership(
      String userId, String invitationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/membership/claim').replace(
          queryParameters: {
            'app_key': appKey,
            'user_id': userId,
            'invitation_code': invitationCode,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 添加应用报告
  static Future<ApiResponse<void>> addAppReport(String report) async {
    final finalReport = await generateReport(report);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/app/report').replace(
          queryParameters: {
            'app_name': appKey, // 使用 appKey 作为应用名称
            'report': finalReport, // 报告内容
          },
        ),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 获取最新版本信息
  static Future<ApiResponse<Map<String, dynamic>>> getLatestVersion(
      [String lang = 'zh']) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/app/latest-version').replace(
          queryParameters: {
            'app_key': appKey,
            'lang': lang,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 添加激活会员的方法
  static Future<ApiResponse<Map<String, dynamic>>> activateVip(
      String invitationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/membership/activate-vip').replace(
          queryParameters: {
            'app_key': appKey,
            'invitation_code': invitationCode,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  static Future<ApiResponse<OrdersResponse>> getUserOrders(
    String userId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/orders/list').replace(
          queryParameters: {
            'app_key': appKey,
            'user_id': userId,
            'page': page.toString(),
            'page_size': pageSize.toString(),
          },
        ),
      );

      return _handleResponse<OrdersResponse>(
        response,
        (json) => OrdersResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 获取产品列表
  static Future<ApiResponse<List<Product>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/products/list').replace(
          queryParameters: {
            'app_key': appKey,
          },
        ),
      );

      return _handleResponse<List<Product>>(
        response,
        (json) => (json['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList(),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 创建订单
  static Future<ApiResponse<Order>> createOrder({
    required String userId,
    required String productId,
    required String payChannel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/create').replace(
          queryParameters: {
            'app_key': appKey,
          },
        ),
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'pay_channel': payChannel,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('raw response: $response');
      return _handleResponse<Order>(
        response,
        (json) => Order.fromJson(json),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 查询订单状态
  static Future<ApiResponse<Map<String, dynamic>>> getOrderStatus(
      String orderNo) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/orders/status').replace(
          queryParameters: {
            'app_key': appKey,
            'order_no': orderNo,
          },
        ),
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }
}
