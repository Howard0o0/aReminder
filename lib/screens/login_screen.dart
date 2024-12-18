import '../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/segmented_code_input.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension BuildContextExtension on BuildContext {
  void pop() {
    if (!mounted) {
      log('not mounted 3');
      return;
    }
    Navigator.of(this).pop();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  static const int _codeLength = 6;
  late AuthProvider _authProvider;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _authProvider.cleanUp();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: CupertinoColors.systemBackground,
          appBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.systemBackground,
            border: null,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.black,
              ),
              onPressed: () {
                _authProvider.cleanUp();
                context.pop();
              },
            ),
          ),
          body: Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGrey5,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            CupertinoTextField.borderless(
                              controller: _emailController,
                              placeholder: l10n.email,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading && !auth.isCodeSent,
                              padding: const EdgeInsets.all(16),
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Icon(
                                  CupertinoIcons.mail,
                                  color: CupertinoColors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (auth.isCodeSent) ...[
                              Container(
                                height: 1,
                                color: CupertinoColors.systemGrey5,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _codeController,
                                  builder: (context, value, child) {
                                    return SegmentedCodeInput(
                                      controller: _codeController,
                                      focusNode: _codeFocusNode,
                                      length: _codeLength,
                                      onChanged: (value) async {
                                        if (value.length != _codeLength) {
                                          return;
                                        }
                                        _codeFocusNode.unfocus();
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        final success = await auth
                                            .verifyEmailAndLogin(value);
                                        if (!mounted) return;
                                        if (success) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          context.pop();
                                          await auth.updateVipStatus();
                                        } else {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          _showError(
                                            context,
                                            auth.lastError ??
                                                l10n.errorInvalidVerificationCode,
                                          );
                                          _codeController.clear();
                                        }
                                      },
                                      keyboardType: TextInputType.number,
                                      height: 44,
                                      fontSize: 20,
                                      borderColor: CupertinoColors.systemGrey4,
                                      borderRadius: 8,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!auth.isCodeSent)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: (!auth.canSendCode || _isLoading)
                                ? CupertinoColors.systemGrey5
                                : CupertinoColors.black,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: (!auth.canSendCode || _isLoading)
                                ? null
                                : () async {
                                    if (_emailController.text.isEmpty) {
                                      _showError(
                                          context, l10n.pleaseInputEmail);
                                      return;
                                    }
                                    if (!_emailController.text.contains('@')) {
                                      _showError(context, l10n.invalidEmail);
                                      return;
                                    }
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    final success =
                                        await auth.sendVerificationCode(
                                      _emailController.text,
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      if (!success) {
                                        _showError(
                                          context,
                                          auth.lastError ??
                                              l10n.errorSendEmailFailed,
                                        );
                                      }
                                    }
                                  },
                            child: _isLoading
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.black)
                                : Text(
                                    auth.countdown > 0
                                        ? '${auth.countdown}s'
                                        : l10n.sendCode,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Container(
            color: CupertinoColors.black.withOpacity(0.1),
            child: const Center(
              child: CupertinoActivityIndicator(
                radius: 15,
              ),
            ),
          ),
      ],
    );
  }
}
