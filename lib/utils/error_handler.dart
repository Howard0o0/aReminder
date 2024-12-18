import 'package:flutter/material.dart';
import '../constants/error_codes.dart';

class ErrorHandler {
  static String getLocalizedMessage(BuildContext context, String errorCode) {
    switch (errorCode) {
      case ErrorCode.invalidEmail:
        return "无效邮箱";
      case ErrorCode.invalidUserData:
        return "无效用户数据";
      case ErrorCode.logoutFailed:
        return "登出失败";

      // 通用错误
      case ErrorCode.unknownError:
        return "未知错误";
      case ErrorCode.networkError:
        return "网络错误";
      case ErrorCode.invalidAppKey:
        return "无效AppKey";
      case ErrorCode.internalError:
        return "内部错误";

      // 用户相关错误
      case ErrorCode.userNotFound:
        return "用户不存在";
      case ErrorCode.userCreateFailed:
        return "创建用户失败";

      // 邀请码相关错误
      case ErrorCode.invitationExisted:
        return "邀请码已存在";
      case ErrorCode.invalidInvitationCode:
        return "无效邀请码";
      case ErrorCode.selfInvitation:
        return "不能邀请自己";

      // 验证码相关错误
      case ErrorCode.invalidVerificationCode:
        return "无效验证码";
      case ErrorCode.sendEmailFailed:
        return "发送邮件失败";

      default:
        return "未知错误";
    }
  }
}
