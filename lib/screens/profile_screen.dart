import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);

    // 使用 addPostFrameCallback 延迟执行刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
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
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
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
                                            ? (auth.user?.userId ?? '非法用户')
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
                                            Text(
                                              auth.isVipValid()
                                                  ? l10n.vipValid
                                                  : l10n.vipInvalid,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: auth.isVipValid()
                                                    ? CupertinoColors.black
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
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            const GetMembershipScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.star,
                                            color: CupertinoColors.black,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.getMembership,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: CupertinoColors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(
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

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  onPressed: () {
                                    final locale =
                                        Localizations.localeOf(context);
                                    final shareUrl =
                                        "https://mirrorcamera.sharpofscience.top";
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
                                            const Text('howardzz@foxmail.com'),
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
                                                        'howardzz@foxmail.com'),
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
}
