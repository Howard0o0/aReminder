import 'dart:async';
import '../services/api_service.dart';
import '../utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../utils/logger.dart';
import 'package:flutter/services.dart';
import 'get_membership_screen.dart';
import '../services/advice_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;
import 'package:fluwx/fluwx.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/misc.dart';

const deviderThickness = 0.15;
const deviderHeight = 15.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late AuthProvider _authProvider;
  Fluwx fluwx = Fluwx();

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);

    // 使用 addPostFrameCallback 延迟执行刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
    });

    _initFluwx();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // 当页面获得焦点时刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    if (_authProvider.isLoggedIn) {
      log('refreshing status');
      await _authProvider.updateVipStatus();
      setState(() {});
    }
  }

  _initFluwx() async {
    await fluwx.registerApi(
      appId: "wx00b1a7cc335532ae",
      doOnAndroid: true,
      doOnIOS: false,
    );
    var result = await fluwx.isWeChatInstalled;
    print('is installed $result');

    fluwx.addSubscriber((response) async {
      if (response is! WeChatAuthResponse) {
        print('not a WeChatAuthResponse, ignore');
        return;
      }

      print(
          '微信登录返回值. type: ${response.type}, code: ${response.code}, state: ${response.state}, country: ${response.country}, lang: ${response.lang}, errCode: ${response.errCode}');

      final errCode = response.errCode;
      final code = response.code;

      if (errCode != 0) {
        switch (errCode) {
          case -4:
            ToastUtils.show('登录失败: 微信授权被拒绝');
            printAndReport('用户拒绝微信授权');
            break;
          case -2:
            ToastUtils.show('登录失败: 微信登录被取消');
            printAndReport('用户取消登录');
          default:
            ToastUtils.show('未知登录错误，错误码: $errCode');
            printAndReport('未知微信登录失败, errCode: $errCode');
            break;
        }
      }

      final success = await _authProvider.wxLogin(code!);
      if (!success) {
        ToastUtils.show('登录失败: 微信登录失败');
        printAndReport('微信登录失败');
      } else {
        ToastUtils.show('登录成功');
      }
    });
  }

  Future<void> wxLogin() async {
    fluwx
        .authBy(
            which: NormalAuth(
      scope: 'snsapi_userinfo',
      state: 'wechat_sdk_demo_test',
    ))
        .then((data) {
      print('微信登录返回值：$data');
    });
  }

  void _copyInvitationCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await Clipboard.setData(ClipboardData(text: code));

      if (!mounted) return;

      // 显示复制成功提示
      showCupertinoDialog(
        context: context,
        barrierDismissible: true, // 点击空白处可关闭
        builder: (context) => CupertinoAlertDialog(
          content: Text(l10n.codeCopied),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              textStyle: const TextStyle(
                color: CupertinoColors.black,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // 显示错误提示
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(l10n.copyFailed), // 需要添加这个翻译
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              textStyle: const TextStyle(
                color: CupertinoColors.black,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> onGetVipButtonClick(BuildContext context) async {
    ApiService.addAppReport('用户点击了获取会员');
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const GetMembershipScreen(),
      ),
    );
    if (_authProvider.isLoggedIn) {
      log('refreshing status after get membership');
      setState(() {});
    }
  }

  void _showAdviceDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final TextEditingController _adviceController = TextEditingController();
    bool _isSubmitting = false;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: Text(l10n?.submitSuggestion ?? '提交建议'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoTextField(
                  controller: _adviceController,
                  maxLines: 4,
                  placeholder: l10n?.pleaseInputYourSuggestion ?? '请输入您的建议...',
                  style: const TextStyle(color: CupertinoColors.black),
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                  decoration: null,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n?.cancel ?? '取消',
                  style: const TextStyle(color: CupertinoColors.black)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_adviceController.text.trim().isEmpty) {
                        ToastUtils.show(
                            l10n?.pleaseInputYourSuggestion ?? '请输入您的建议...');
                        return;
                      }

                      setState(() {
                        _isSubmitting = true;
                      });

                      final success = await AdviceService(context).submitAdvice(
                        _adviceController.text.trim(),
                      );

                      if (success) {
                        Navigator.pop(context);
                        ToastUtils.show(
                            l10n?.thankYouForYourSuggestion ?? '感谢您的建议！');
                      } else {
                        ToastUtils.show(
                            l10n?.submitSuggestionFailed ?? '提交失败，请稍后重试');
                      }
                    },
              child: Text(
                  _isSubmitting
                      ? l10n?.submitting ?? '提交中...'
                      : l10n?.submitSuggestion ?? '提交',
                  style: const TextStyle(color: CupertinoColors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVersionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('版本信息'),
        content: Text('${packageInfo.version} (${packageInfo.buildNumber})'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            textStyle: const TextStyle(
              color: CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: !auth.isLoggedIn
                        ? () {
                            _showLoginOptions(context);
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.person_alt_circle,
                                    size: 30,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auth.isLoggedIn
                                            ? auth.userNickname()
                                            : l10n.pleaseLogin,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                      if (auth.isLoggedIn) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            auth.isVipValid()
                                                ? Image.asset(
                                                    'asset/image/vip.png',
                                                    width: 36,
                                                    // height: 24,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Text(
                                                    l10n.vipInvalid,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: auth.isVipValid()
                                                          ? CupertinoColors
                                                              .black
                                                          : CupertinoColors
                                                              .secondaryLabel,
                                                    ),
                                                  ),
                                            if (auth.isVipValid() &&
                                                auth.vipExpireDate != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '${l10n.expireDate}: ${auth.vipExpireDate}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: CupertinoColors.black,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (auth.isLoggedIn &&
                              auth.user?.invitationCode != null)
                            GestureDetector(
                              onTap: () => _copyInvitationCode(
                                  context, auth.user!.invitationCode!),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.black
                                          .withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.ticket,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'UUID: ${auth.user?.invitationCode}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.doc_on_doc,
                                        color: CupertinoColors.systemGrey,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9A9E),
                                  Color(0xFFFAD0C4),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF9A9E).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => onGetVipButtonClick(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'asset/image/logo_round.png',
                                      width: 32,
                                      height: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '开通 PRO',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      CupertinoColors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // 只有登录后才显示查看订单按钮
                                if (auth.isLoggedIn) ...[
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              const OrdersScreen(),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.doc_text,
                                              color: CupertinoColors.black,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "订单管理",
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          CupertinoIcons.chevron_right,
                                          color: CupertinoColors.black,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: deviderHeight,
                                    thickness: deviderThickness,
                                    color: CupertinoColors.separator,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                ],

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () {
                                    final locale =
                                        Localizations.localeOf(context);
                                    final shareUrl = ApiService.officialWebsite;
                                    Clipboard.setData(
                                        ClipboardData(text: shareUrl));
                                    ToastUtils.show(l10n.shareLinkCopied);
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.share,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.shareApp,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            const SettingsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.settings,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '设置',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () => _showAdviceDialog(context),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.chat_bubble_text,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.suggestionDialogTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () {
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoAlertDialog(
                                        title: Text(l10n.contactUs),
                                        content:
                                            const Text(
                                            'support@quantum-realm.ltd'),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: Text(l10n.copy,
                                                style: const TextStyle(
                                                    color:
                                                        CupertinoColors.black)),
                                            onPressed: () async {
                                              await Clipboard.setData(
                                                const ClipboardData(
                                                    text:
                                                        'support@quantum-realm.ltd'),
                                              );
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                              ToastUtils.show(l10n.copied);
                                            },
                                          ),
                                          CupertinoDialogAction(
                                            child: const Text('OK',
                                                style: TextStyle(
                                                    color:
                                                        CupertinoColors.black)),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.mail,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.contactUs,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // 退出登录和注销账号按钮
                                if (auth.isLoggedIn) ...[
                                  // 退出登录按钮
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    onPressed: () {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                          title: Text(l10n.logoutConfirmTitle),
                                          content:
                                              Text(l10n.logoutConfirmMessage),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: Text(l10n.cancel),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              isDefaultAction: true,
                                            ),
                                            CupertinoDialogAction(
                                              child: Text(l10n.logout),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                auth.logout();
                                              },
                                              isDestructiveAction: true,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.square_arrow_left,
                                              color: CupertinoColors.black,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              l10n.logout,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: deviderHeight,
                                    thickness: deviderThickness,
                                    color: CupertinoColors.separator,
                                    indent: 16,
                                    endIndent: 16,
                                  ),

                                  // 注销账号按钮
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    onPressed: () {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                          title: Text(
                                              l10n.deleteAccountConfirmTitle),
                                          content: Text(
                                              l10n.deleteAccountConfirmMessage),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: Text(l10n.cancel),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              isDefaultAction: true,
                                            ),
                                            CupertinoDialogAction(
                                              child: Text(l10n.delete),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                auth.logout();
                                              },
                                              isDestructiveAction: true,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.delete,
                                              color: CupertinoColors
                                                  .destructiveRed,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              l10n.deleteAccount,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: CupertinoColors
                                                    .destructiveRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: deviderHeight,
                                    thickness: deviderThickness,
                                    color: CupertinoColors.separator,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                ],

                                // 在联系我们按钮后面添加版本按钮
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () => _showVersionDialog(context),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.info_circle,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '版本信息',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // 在联系我们后面添加小红书关注按钮
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () async {
                                    const url =
                                        'https://www.xiaohongshu.com/user/profile/67399a09000000001c019fde';
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      if (!context.mounted) return;
                                      ToastUtils.show('无法打开链接');
                                    }
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.heart,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '关注小红书官方账号',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: deviderHeight,
                                  thickness: deviderThickness,
                                  color: CupertinoColors.separator,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () async {
                                    const url =
                                        'https://mirrorcamera.sharpofscience.top/ireminder-privacy.html';
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      if (!context.mounted) return;
                                      ToastUtils.show('无法打开链接');
                                    }
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.person,
                                        color: CupertinoColors.black,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '隐私政策',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImageCard(BuildContext context, String imageUrl) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onLongPress: () {
                  // TODO: 保存图片到相册
                },
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(
                            radius: 16,
                          ),
                          const SizedBox(height: 10),
                          if (loadingProgress.expectedTotalBytes != null)
                            Text(
                              '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: CupertinoColors.systemRed,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '无法打开链接',
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(l10n.cancel,
                style: const TextStyle(color: CupertinoColors.black)),
          ),
        ],
      ),
    );
  }

  void _showReportOptionsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text("选择客服"),
        // message: Text(""),
        actions: [
          CupertinoActionSheetAction(
            child: Text(
              "微信客服",
              style: const TextStyle(color: CupertinoColors.activeBlue),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showImageCard(context,
                  "https://mirrorcamera.sharpofscience.top/wecom_hwzhu.jpg");
            },
          ),
          CupertinoActionSheetAction(
            child: Text(
              "Telegram 客服",
              style: const TextStyle(color: CupertinoColors.activeBlue),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showImageCard(context,
                  "https://mirrorcamera.sharpofscience.top/telegram_hwzhu.jpg");
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: CupertinoColors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showLoginOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('选择登录方式'),
        // message: Text(''),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              wxLogin();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('微信登录',
                    style: TextStyle(color: CupertinoColors.activeBlue)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
              if (result == true) {
                _refreshStatus();
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('邮箱登录',
                    style: TextStyle(color: CupertinoColors.activeBlue)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child:
              Text(l10n.cancel, style: TextStyle(color: CupertinoColors.black)),
        ),
      ),
    );
  }
}
