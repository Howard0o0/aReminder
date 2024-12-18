class ErrorCode {
  static const String invalidEmail = 'INVALID_EMAIL';
  static const String invalidUserData = 'INVALID_USER_DATA';
  static const String logoutFailed = 'LOGOUT_FAILED';

  // 通用错误
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String invalidAppKey = 'INVALID_APP_KEY';
  static const String internalError = 'INTERNAL_ERROR';
  
  // 用户相关错误
  static const String userNotFound = 'USER_NOT_FOUND';
  static const String userCreateFailed = 'USER_CREATE_FAILED';
  
  // 邀请码相关错误
  static const String invitationExisted = 'INVITATION_EXISTED';
  static const String invalidInvitationCode = 'INVALID_INVITATION_CODE';
  static const String selfInvitation = 'SELF_INVITATION';
  
  // 验证码相关错误
  static const String invalidVerificationCode = 'INVALID_VERIFICATION_CODE';
  static const String sendEmailFailed = 'SEND_EMAIL_FAILED';
} 