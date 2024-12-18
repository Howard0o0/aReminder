import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import '../widgets/segmented_code_input.dart';
import 'dart:io';

class GetMembershipScreen extends StatefulWidget {
  const GetMembershipScreen({super.key});

  @override
  State<GetMembershipScreen> createState() => _GetMembershipScreenState();
}

class _GetMembershipScreenState extends State<GetMembershipScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  static const int _codeLength = 7;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCodeInput(BuildContext context, String value) async {
    if (value.length == _codeLength) {
      setState(() {
        _isLoading = true;
      });

      // 让输入框失去焦点，键盘会自动收起
      _focusNode.unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.claimMembership(value);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            content: Text(AppLocalizations.of(context)!.membershipActivated),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
                textStyle: const TextStyle(color: CupertinoColors.black),
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            content: Text(authProvider.lastError ??
                AppLocalizations.of(context)!.activationFailed),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
                textStyle: const TextStyle(color: CupertinoColors.black),
              ),
            ],
          ),
        );
        _codeController.clear();
      }
    }
  }

  Widget _buildPurchaseCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.shopping_cart,
                color: CupertinoColors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.purchaseMembership,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                // 购买按钮
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: CupertinoColors.black,
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                l10n.lifetimeVip,
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                          Text(
                            l10n.lifetimeVipPrice,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onPressed: () async {
                      try {
                        // TODO
                        // Buy membership
                      } catch (e) {
                        if (!mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: Text(l10n.purchaseError),
                            content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 恢复购买按钮
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: CupertinoColors.systemGrey5,
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          l10n.restore,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.black,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        // TODO
                        // Check past purchases
                      } catch (e) {
                        if (!mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: Text(l10n.restoreError),
                            content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: CupertinoColors.systemBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: CupertinoColors.black,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.getMembership,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.sparkles,
                                color: CupertinoColors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.membershipBenefits,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Table(
                            border: TableBorder.all(
                              color: CupertinoColors.systemGrey5,
                              width: 1,
                            ),
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                ),
                                children: [
                                  _buildTableCell(l10n.nonMember, true),
                                  _buildTableCell(l10n.member, true),
                                ],
                              ),
                              TableRow(
                                children: [
                                  _buildTableCell('最多10个待办事项', false),
                                  _buildTableCell('无限制', false),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      _buildPurchaseCard(context),
                    ],
                    const SizedBox(height: 16),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: CupertinoColors.white,
                    //     borderRadius: BorderRadius.circular(10),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: CupertinoColors.black.withOpacity(0.05),
                    //         blurRadius: 10,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   padding: const EdgeInsets.all(16),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Row(
                    //         children: [
                    //           const Icon(
                    //             CupertinoIcons.gift,
                    //             color: CupertinoColors.black,
                    //           ),
                    //           const SizedBox(width: 8),
                    //           Text(
                    //             l10n.shareToGetMembership,
                    //             style: const TextStyle(
                    //               fontSize: 15,
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 12),
                    //       Text(
                    //         l10n.shareToGetMembershipDesc,
                    //         style: const TextStyle(
                    //           fontSize: 15,
                    //           color: CupertinoColors.secondaryLabel,
                    //         ),
                    //       ),
                    //       if (auth.invitationCode != null) ...[
                    //         const SizedBox(height: 12),
                    //         Container(
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 12,
                    //             vertical: 8,
                    //           ),
                    //           decoration: BoxDecoration(
                    //             color: CupertinoColors.systemGrey6,
                    //             borderRadius: BorderRadius.circular(8),
                    //           ),
                    //           child: Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Text(
                    //                 auth.invitationCode!,
                    //                 style: const TextStyle(
                    //                   fontSize: 17,
                    //                   fontWeight: FontWeight.w500,
                    //                 ),
                    //               ),
                    //               CupertinoButton(
                    //                 padding: EdgeInsets.zero,
                    //                 onPressed: () => _copyInvitationCode(
                    //                     context, auth.invitationCode!),
                    //                 child: const Icon(
                    //                   CupertinoIcons.doc_on_doc,
                    //                   color: CupertinoColors.black,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ],
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: CupertinoColors.white,
                    //     borderRadius: BorderRadius.circular(10),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: CupertinoColors.black.withOpacity(0.05),
                    //         blurRadius: 10,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   padding: const EdgeInsets.all(16),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Row(
                    //         children: [
                    //           const Icon(
                    //             CupertinoIcons.star,
                    //             color: CupertinoColors.black,
                    //           ),
                    //           const SizedBox(width: 8),
                    //           Text(
                    //             l10n.enterCodeToGetMembership,
                    //             style: const TextStyle(
                    //               fontSize: 15,
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 12),
                    //       Text(
                    //         l10n.enterCodeToGetMembershipDesc,
                    //         style: const TextStyle(
                    //           fontSize: 15,
                    //           color: CupertinoColors.secondaryLabel,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 12),
                    //       SegmentedCodeInput(
                    //         controller: _codeController,
                    //         focusNode: _focusNode,
                    //         length: _codeLength,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             _handleCodeInput(context, value);
                    //           });
                    //         },
                    //         keyboardType: TextInputType.numberWithOptions(
                    //           decimal: false,
                    //         ),
                    //         textCapitalization: TextCapitalization.none,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
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

  void _copyInvitationCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(l10n.codeCopied),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
              textStyle: const TextStyle(color: CupertinoColors.black),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(l10n.copyFailed),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
              textStyle: const TextStyle(color: CupertinoColors.black),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTableCell(String text, bool isHeader, {bool noWrap = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: noWrap ? TextOverflow.ellipsis : TextOverflow.visible,
        softWrap: !noWrap,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color:
              isHeader ? CupertinoColors.black : CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}
