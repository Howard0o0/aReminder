import '../utils/logger.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../constants/error_codes.dart';
import 'dart:async';
import '../providers/auth_provider.dart';

class AuthProvider with ChangeNotifier {
  static const String _userKey = 'user_data';

  User? _user;
  bool _isLoading = false;
  String? _email;
  bool _isCodeSent = false;
  String? _lastError;
  BuildContext? _context;
  int _countdown = 0;
  Timer? _timer;
  bool _isLifetimeVip = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  // bool get isVipValid => _user?.isVipValid ?? false;
  bool get isCodeSent => _isCodeSent;
  String? get email => _email;
  String? get lastError => _lastError;
  int get countdown => _countdown;
  bool get canSendCode => _countdown == 0;
  String? get vipExpireDate => _user?.formattedExpireDate;
  String? get invitationCode => _user?.invitationCode;

  AuthProvider() {
    _loadUserFromStorage();
    _checkLifetimeVip();
  }

  bool isVipValid() {
    if (_isLifetimeVip) return true;
    return _user?.isVipValid ?? false;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void _setError(String? errorCode) {
    log('setError: $errorCode');
    if (errorCode == null) {
      _lastError = null;
    } else if (_context != null) {
      log('lastError: ${ErrorHandler.getLocalizedMessage(_context!, errorCode)}');
      _lastError = ErrorHandler.getLocalizedMessage(_context!, errorCode);
    }
    notifyListeners();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        try {
          _user = User.fromJson(jsonDecode(userStr));
          notifyListeners();
        } catch (e) {
          log('Error parsing user data: $e');
        }
      }
    } catch (e) {
      log('Error loading from SharedPreferences: $e');
      // 错误处理，但不影响程序运行
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      log('Error saving to SharedPreferences: $e');
      // 即使存储失败，也不影响登录状态
    }
  }

  // 始倒计时
  void _startCountdown() {
    _countdown = 10; // 10秒倒计时
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      if (_countdown <= 0) {
        _timer?.cancel();
        _countdown = 0;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String userNickname() {
    if (_user?.nickname != null) {
      return _user!.nickname!;
    }
    return _user!.userId;
  }

  // 验证邮箱并登录
  Future<bool> wxLogin(String code) async {
    if (code == null) {
      _setError(ErrorCode.invalidEmail);
      return false;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final verifyResponse = await ApiService.wxLogin(code);
      if (!verifyResponse.success) {
        _setError(verifyResponse.errorCode ?? ErrorCode.unknownError);
        return false;
      }

      final userData = verifyResponse.data;
      if (userData == null || userData['user_id'] == null) {
        _setError(ErrorCode.invalidUserData);
        return false;
      }

      final membershipResponse =
          await ApiService.getMembershipStatus(userData['user_id']);
      if (!membershipResponse.success) {
        _setError(membershipResponse.errorCode ?? ErrorCode.unknownError);
        return false;
      }

      final membershipData = membershipResponse.data;
      print('membershipData: $membershipData');

      _user = User(
        userId: userData['user_id'],
        appKey: ApiService.appKey,
        isVip: membershipData?['is_member'] ?? false,
        vipExpiredAt: membershipData?['expire_time'] != null
            ? DateTime.parse(membershipData!['expire_time'])
            : null,
        invitationCode: membershipData?['invitation_code'],
        nickname: userData['nickname'],
        avatarUrl: userData['avatar_url'],
      );

      log('user login. user info: ${_user?.toJson()}');

      try {
        await _saveUserToStorage(_user!);
      } catch (e) {
        log('Error saving user data: $e');
      }

      _isCodeSent = false;
      _email = null;

      await _checkLifetimeVip();
      return true;
    } catch (e) {
      _setError(ErrorCode.networkError);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    if (!canSendCode) return false;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await ApiService.sendVerificationCode(email);
      if (response.success) {
        _email = email;
        _isCodeSent = true;
        _startCountdown();
        return true;
      } else {
        _setError(response.errorCode ?? ErrorCode.unknownError);
        return false;
      }
    } catch (e) {
      _setError(ErrorCode.networkError);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 验证邮箱并登录
  Future<bool> verifyEmailAndLogin(String code) async {
    if (_email == null) {
      _setError(ErrorCode.invalidEmail);
      return false;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final verifyResponse = await ApiService.verifyEmail(_email!, code);
      if (!verifyResponse.success) {
        _setError(verifyResponse.errorCode ?? ErrorCode.unknownError);
        return false;
      }

      final userData = verifyResponse.data;
      if (userData == null || userData['user_id'] == null) {
        _setError(ErrorCode.invalidUserData);
        return false;
      }

      final membershipResponse =
          await ApiService.getMembershipStatus(userData['user_id']);
      if (!membershipResponse.success) {
        _setError(membershipResponse.errorCode ?? ErrorCode.unknownError);
        return false;
      }

      final membershipData = membershipResponse.data;

      _user = User(
        userId: userData['user_id'],
        appKey: ApiService.appKey,
        isVip: membershipData?['is_vip'] ?? false,
        vipExpiredAt: membershipData?['expired_at'] != null
            ? DateTime.parse(membershipData!['expired_at'])
            : null,
        invitationCode: userData['invitation_code'],
      );

      log('user login. user info: ${_user?.toJson()}');

      try {
        await _saveUserToStorage(_user!);
      } catch (e) {
        log('Error saving user data: $e');
      }

      _isCodeSent = false;
      _email = null;

      await _checkLifetimeVip();
      return true;
    } catch (e) {
      _setError(ErrorCode.networkError);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加清理用户数据的方法
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      log('Error clearing user data: $e');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 修改 logout 方法
  Future<void> logout() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _clearUserData();
      _user = null;
      _email = null;
      _isCodeSent = false;
    } catch (e) {
      _setError(ErrorCode.logoutFailed);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVipStatus() async {
    if (_user == null) return false;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('updating vip status. user id: ${_user!.userId}');
      final response = await ApiService.getMembershipStatus(_user!.userId);
      if (!response.success) {
        _setError(response.errorCode ?? ErrorCode.unknownError);
        return false;
      }

      final membershipData = response.data;
      _user = User(
        userId: _user!.userId,
        appKey: _user!.appKey,
        isVip: membershipData?['is_member'] ?? false,
        vipExpiredAt: membershipData?['expire_time'] != null
            ? DateTime.parse(membershipData!['expire_time'])
            : null,
        invitationCode: membershipData?['invitation_code'],
        nickname: _user!.nickname,
        avatarUrl: _user!.avatarUrl,
      );

      await _saveUserToStorage(_user!);
      await _checkLifetimeVip();
      print('vip status updated. user isVip: ${_user!.isVip}');
      return true;
    } catch (e) {
      _setError(ErrorCode.networkError);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 清除错误信息
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // 重置所有状态
  void reset() {
    _isLoading = false;
    _countdown = 0;
    _timer?.cancel();
    _timer = null;
    _email = null;
    _isCodeSent = false;
    _lastError = null;
  }

  // 修改 cleanUp 方法，添加所有状态的重置
  void cleanUp() {
    _timer?.cancel();
    _timer = null;
    _isLoading = false;
    _countdown = 0;
    _email = null;
    _isCodeSent = false; // 重置验证码发送状态
    _lastError = null;
    // notifyListeners(); // 通知监听器状态已更新
  }

  Future<bool> claimMembership(String invitationCode) async {
    if (_user == null) return false;

    _isLoading = true;
    _lastError = null;

    try {
      final response =
          await ApiService.claimMembership(_user!.userId, invitationCode);
      if (!response.success) {
        _setError(response.errorCode ?? ErrorCode.unknownError);
        return false;
      }
      return true;
    } catch (e) {
      _setError(ErrorCode.networkError);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateLifetimeVip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lifetime_vip', true);

      final expiredAt = DateTime.now().add(const Duration(days: 365 * 200));
      _isLifetimeVip = true;

      if (_user != null) {
        _user = User(
          userId: _user!.userId,
          appKey: _user!.appKey,
          isVip: true,
          vipExpiredAt: expiredAt, // 永久会员无过期时间
          invitationCode: _user!.invitationCode,
          nickname: _user!.nickname,
          avatarUrl: _user!.avatarUrl,
        );
        await _saveUserToStorage(_user!);
      }
      print('activate lifetime vip!');

      notifyListeners();
    } catch (e) {
      print('Error activating lifetime VIP: $e');
    }
  }

  Future<void> _checkLifetimeVip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLifetimeVip = prefs.getBool('lifetime_vip') ?? false;
      if (isLifetimeVip) {
        await activateLifetimeVip();
      }
    } catch (e) {
      print('Error checking lifetime VIP status: $e');
    }
  }
}
