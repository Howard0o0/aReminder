class User {
  final String userId;
  final String appKey;
  final bool isVip;
  final DateTime? vipExpiredAt;
  final String? invitationCode;

  User({
    required this.userId,
    required this.appKey,
    required this.isVip,
    this.vipExpiredAt,
    this.invitationCode,
  });

  bool get isVipValid {
    if (!isVip) return false;
    if (vipExpiredAt == null) return false;
    return vipExpiredAt!.isAfter(DateTime.now());
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      appKey: json['app_key'] ?? '',
      isVip: json['is_vip'] ?? false,
      vipExpiredAt: json['vip_expired_at'] != null 
          ? DateTime.parse(json['vip_expired_at'])
          : null,
      invitationCode: json['invitation_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'app_key': appKey,
      'is_vip': isVip,
      'vip_expired_at': vipExpiredAt?.toIso8601String(),
      'invitation_code': invitationCode,
    };
  }

  String? get formattedExpireDate {
    if (!isVipValid || vipExpiredAt == null) return null;
    // 格式化为 yyyy-MM-dd
    return '${vipExpiredAt!.year}-${vipExpiredAt!.month.toString().padLeft(2, '0')}-${vipExpiredAt!.day.toString().padLeft(2, '0')}';
  }
} 