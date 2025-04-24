import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import '../widgets/segmented_code_input.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../providers/product_provider.dart';
import '../utils/toast_utils.dart';
import 'dart:convert' show utf8;
import '../models/product.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'dart:math';

class GetMembershipScreen extends StatefulWidget {
  const GetMembershipScreen({super.key});

  @override
  State<GetMembershipScreen> createState() => _GetMembershipScreenState();
}

class _GetMembershipScreenState extends State<GetMembershipScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  static const int _codeLength = 7;
  bool _isLoading = false;
  bool _isLoadingProducts = true;
  String _selectedProductId = '';
  List<Product> _products = [];
  bool _agreedToTerms = false;
  // 新增晃动动画控制器
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Order? curr_order;

  final api_service = ApiService();

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在构建完成后执行
    print('initState called'); // 调试日志

    // 初始化晃动动画控制器
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 创建晃动动画
    _shakeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      log('fetching products');
      await productProvider.fetchProducts();
      setState(() {
        _products = productProvider.products;
        _isLoadingProducts = false;
      });

      String productIDList = "";
      for (var product in _products) {
        productIDList += '${product.productId}, ';
      }
      ApiService.addAppReport('获取产品列表成功. 获取到: $productIDList');
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // 添加协议勾选框构建方法
  Widget _buildTermsAgreement() {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              _shakeAnimation.value *
                  10 *
                  sin(_shakeAnimation.value * 3 * 3.14),
              0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CupertinoCheckbox(
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              activeColor: const Color(0xFFFF416C),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              const url =
                  "https://mirrorcamera.sharpofscience.top/ireminder-vip-protocol.html";
              try {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ToastUtils.show('无法打开会员协议');
                  }
                }
              } catch (e) {
                if (mounted) {
                  ToastUtils.show('打开链接失败: $e');
                }
              }
            },
            child: Text(
              '我已阅读会员协议(点我阅读)',
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.035,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.06;

    // 定义特性列表
    final List<(IconData, String)> _features = [
      (CupertinoIcons.sparkles, "待办事项数量无限制"),
      (CupertinoIcons.sparkles, "现在购买享受早鸟价"),
      (CupertinoIcons.sparkles, "享受后续更新的所有新功能"),
      (CupertinoIcons.sparkles, "可重复购买, 增加会员期限"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              'asset/image/beauty_vilet.png',
              fit: BoxFit.cover,
            ),
          ),
          // 半透明遮罩层
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: SizedBox(
              // 添加 SizedBox 提供固定高度约束
              height: size.height,
              child: Column(
                children: [
                  // 上部分 (固定高度)
                  SizedBox(
                    height: size.height * 0.5, // 保持固定为屏幕高度的 1/3
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 返回按钮
                        Padding(
                          padding: EdgeInsets.all(padding),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                            child: Icon(
                              CupertinoIcons.back,
                              color: Colors.white,
                              size: size.width * 0.06,
                            ),
                          ),
                        ),
                        // VIP标题和特权列表
                        Expanded(
                          // 使用 Expanded 让特权列表填充剩余空间
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'iReminder ',
                                      style: TextStyle(
                                        fontSize: size.width * 0.08,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width * 0.08,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: size.height * 0.02),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: _features
                                        .map(
                                          (feature) => Padding(
                                            padding: EdgeInsets.only(
                                                bottom: size.height * 0.02),
                                            child: _buildFeatureItem(
                                                feature.$1, feature.$2),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 中间用 Spacer 自动填充空间
                  const Spacer(),

                  // 下部分（自适应高度）
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 使用最小所需空间
                      children: [
                        // 会员选项
                        _buildMembershipOptions(),
                        // 协议勾选框
                        _buildTermsAgreement(),
                        // 底部购买按钮
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: size.height * 0.03, // 底部固定padding
                            top: size.height * 0.02,
                          ),
                          child: _buildPurchaseButton(l10n),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading 遮罩层
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "请稍等...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    final size = MediaQuery.of(context).size;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: size.width * 0.07, color: Colors.white),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: size.width * 0.045,
              color: Colors.white,
              height: 1.2,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
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

  Widget _buildMembershipOptions() {
    final size = MediaQuery.of(context).size;

    if (_isLoadingProducts) {
      return Container(
        height: size.height * 0.25, // 屏幕高度的25%
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(size.width * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: size.width * 0.025,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: size.width * 0.025,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CupertinoActivityIndicator(
                  radius: size.width * 0.035,
                  color: const Color(0xFFFF416C),
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(size.width * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: size.width * 0.02,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: const Color(0xFFFF416C),
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _products.map((product) {
        final isSelected = _selectedProductId == product.productId;
        String priceDisplay = '';
        String? savedAmount;
        String? originalPrice;

        originalPrice = _calculateOriginalPrice(product);
        final savedPrice = _calculateSavedAmount(product);
        final formattedPrice = product.amount.toStringAsFixed(2);
        priceDisplay =
            "${formattedPrice} / ${_getPlanPeriod(product.productType)}";
        savedAmount = '节省$savedPrice';

        return Padding(
          padding: EdgeInsets.only(bottom: size.height * 0.01),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _selectedProductId = product.productId;
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[200],
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.grey[200]!,
                        width: size.width * 0.005,
                      ),
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          priceDisplay,
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      if (savedAmount != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '原价 ' + (originalPrice ?? ''),
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                                fontSize: size.width * 0.03,
                              ),
                            ),
                            SizedBox(width: size.width * 0.01),
                            Text(
                              savedAmount,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: size.width * 0.03,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.black,
                          size: size.width * 0.05,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getPlanPeriod(int productId) {
    if (productId == 1) return '周';
    if (productId == 2) return '年';
    if (productId == 3) return '永久';
    return '';
  }

  double rawPriceFactor = 1.5;

  String _calculateOriginalPrice(Product product) {
    final price = (product.amount * rawPriceFactor).toDouble();
    return "¥${price.toStringAsFixed(2)}";
  }

  String _calculateSavedAmount(Product product) {
    final originalPrice = product.amount * rawPriceFactor;
    final savedAmount = (originalPrice - product.amount).toDouble();
    return "¥${savedAmount.toStringAsFixed(2)}";
  }

  Future<void> finishPayment() async {
    if (curr_order == null) {
      ApiService.addAppReport('订单不存在');
      if (mounted) {
        ToastUtils.showDialog(
          context,
          '查询订单失败',
          '订单信息不存在',
        );
      }
      return;
    }

    try {
      final resp = await ApiService.getOrderStatus(curr_order!.orderNo);

      if (!resp.success) {
        ApiService.addAppReport(
            '查询订单失败: ${resp.success}, errcode: ${resp.errorCode}, message: ${resp.message}');
        if (mounted) {
          ToastUtils.showDialog(
            context,
            '查询订单失败',
            resp.message ?? '未知错误',
          );
        }
        return;
      }

      final orderStatus = resp.data!;
      log('orderStatus: $orderStatus');
      if (orderStatus['pay_status'].toString() == "1") {
        ApiService.addAppReport('订单支付成功');

        // 支付成功
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.updateVipStatus();
        ApiService.addAppReport('更新会员状态: $success');

        if (success) {
          if (mounted) {
            ToastUtils.show('购买成功');
          }
        } else {
          if (mounted) {
            ToastUtils.showDialog(
              context,
              '更新会员状态失败',
              '请稍后在设置中刷新会员状态',
            );
          }
        }
      } else {
        // 未支付
        ApiService.addAppReport('订单未支付');
        if (mounted) {
          ToastUtils.showDialog(
            context,
            '支付未完成',
            '订单未支付成功，请到订单管理页面完成支付',
          );
        }
      }
    } catch (e) {
      ApiService.addAppReport('查询订单失败: $e');
      if (mounted) {
        ToastUtils.showDialog(
          context,
          '查询订单失败',
          e.toString(),
        );
      }
    }
  }

  // 晃动文本标签的方法
  void _shakeTermsText() {
    _shakeController.reset();
    _shakeController.forward();
  }

  // 为了保持代码整洁，建议将购买按钮抽取为单独的方法
  Widget _buildPurchaseButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF416C),
              Color(0xFFFF4B2B),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          onPressed: _isLoading
              ? null
              : () async {
                  ApiService.addAppReport('点击了购买按钮');

                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final user = authProvider.user;
                  if (user == null) {
                    ToastUtils.show('请登录');
                    ApiService.addAppReport('购买时未登录');
                    return;
                  }

                  // 检查是否同意了协议
                  if (!_agreedToTerms) {
                    _shakeTermsText();
                    ToastUtils.show('请先阅读并同意会员协议');
                    ApiService.addAppReport('用户未同意会员协议');
                    return;
                  }

                  if (_selectedProductId == '') {
                    ToastUtils.show('请选择1个购买方案');
                    ApiService.addAppReport('购买时没有选择购买方案');
                    return;
                  }
                  setState(() {
                    _isLoading = true;
                  });

                  ApiService.addAppReport('正在购买: $_selectedProductId');
                  try {
                    final resp = await ApiService.createOrder(
                      userId: user.userId,
                      productId: _selectedProductId,
                      payChannel: 'alipay',
                    );
                    log('resp. success: ${resp.success}, errcode: ${resp.errorCode}, message: ${resp.message}');
                    ApiService.addAppReport(
                        '创建订单: ${resp.success}, errcode: ${resp.errorCode}, message: ${resp.message}');

                    if (!resp.success) {
                      if (!mounted) return;
                      ToastUtils.showDialog(
                          context, '创建订单失败', resp.message ?? '');
                      return;
                    }

                    curr_order = resp.data;
                    log('curr_order: ${curr_order!}');

                    if (curr_order!.payUrl == null && mounted) {
                      ToastUtils.showDialog(
                        context,
                        '生成订单失败',
                        '服务器出错, 支付链接为空, 请联系我们',
                      );
                      ApiService.addAppReport(
                          '获取到的订单 url 为空. order_no: ${curr_order?.orderNo} ');
                      return;
                    }

                    if (!await canLaunchUrl(Uri.parse(curr_order!.payUrl!)) &&
                        mounted) {
                      ToastUtils.showDialog(
                        context,
                        '生成订单失败',
                        '服务器出错, 生成的支付链接不可访问: ${curr_order!.payUrl}',
                      );
                      ApiService.addAppReport(
                          '生成的支付链接不可访问: ${curr_order!.payUrl}');
                      return;
                    }

                    await launchUrl(Uri.parse(curr_order!.payUrl!));
                    ApiService.addAppReport('已跳转到支付链接: ${curr_order!.payUrl}');

                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('支付确认'),
                          content: const Text('请支付后确认状态'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text(
                                '已完成支付',
                                style: TextStyle(color: Color(0xFFFF416C)),
                              ),
                              onPressed: () async {
                                ApiService.addAppReport('点击了已完成支付');
                                Navigator.of(context).pop(); // 只关闭对话框
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  await finishPayment();
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                            ),
                            CupertinoDialogAction(
                              child: const Text(
                                '放弃支付',
                                style: TextStyle(color: Colors.grey),
                              ),
                              onPressed: () {
                                ApiService.addAppReport('点击了放弃支付');
                                Navigator.of(context).pop(); // 只关闭对话框
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ToastUtils.showDialog(
                      context,
                      l10n.purchaseError,
                      e.toString(),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                )
              : Text(
                  l10n.getMembership,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
