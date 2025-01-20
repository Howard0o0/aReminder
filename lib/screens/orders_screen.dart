import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../utils/toast_utils.dart';
import 'dart:convert'; // 添加这个导入

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<ApiResponse<OrdersResponse>> _ordersFuture;
  final _refreshController = CupertinoSliverRefreshControl();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).user?.userId;
    if (userId != null) {
      _ordersFuture = ApiService.getUserOrders(userId);
    }
  }

  String _getStatusText(Order order) {
    if (order.payStatus == 1) return '已支付';
    if (order.payStatus == 2 || !order.isValid) return '已取消';
    return '待支付';
  }

  Color _getStatusColor(Order order) {
    if (order.payStatus == 1) return CupertinoColors.systemGreen;
    if (order.payStatus == 2 || !order.isValid)
      return CupertinoColors.systemGrey;
    return CupertinoColors.systemOrange;
  }

  Future<void> _handlePayment(Order order) async {
    if (!order.canPay) return;

    final uri = Uri.parse(order.payUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('订单状态', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
      ),
      child: SafeArea(
        child: FutureBuilder<ApiResponse<OrdersResponse>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (snapshot.hasError || !snapshot.data!.success) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 50,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.data?.message ?? '加载失败',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!.data!.orders;
            
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.doc_text,
                      size: 50,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '暂无订单',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    setState(() {
                      _loadOrders();
                    });
                  },
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 8),
                    child: Center(
                      child: Text(
                        '下拉刷新',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = orders[index];
                        return OrderCard(
                          order: order,
                          onPayment: _handlePayment,
                        );
                      },
                      childCount: orders.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PaymentButton extends StatelessWidget {
  final Order order;
  final Function(Order) onPayment;
  final bool fullWidth;

  const PaymentButton({
    super.key,
    required this.order,
    required this.onPayment,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!order.canPay) return const SizedBox.shrink();

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: CupertinoColors.activeBlue,
        borderRadius: BorderRadius.circular(8),
        child: const Text(
          '去支付',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () => onPayment(order),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(Order) onPayment;

  const OrderCard({
    super.key,
    required this.order,
    required this.onPayment,
  });

  Color _getStatusColor(Order order) {
    if (order.payStatus == 1) return CupertinoColors.systemGreen;
    if (order.payStatus == 2 || !order.isValid)
      return CupertinoColors.systemGrey;
    return CupertinoColors.systemOrange;
  }

  String _getStatusText(Order order) {
    if (order.payStatus == 1) return '已支付';
    if (order.payStatus == 2 || !order.isValid) return '已取消';
    return '待支付';
  }

  String _decodeProductName(String encodedName) {
    try {
      // 先尝试 UTF-8 解码
      List<int> bytes = latin1.encode(encodedName);
      return utf8.decode(bytes);
    } catch (e) {
      // 如果解码失败，返回原始字符串
      return encodedName;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey4.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '订单详情',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.cube_box,
                                color: CupertinoColors.activeBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _decodeProductName(order.productName),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '订单信息',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailItem(title: '订单号', value: order.orderNo),
                      _DetailItem(
                          title: '创建时间',
                          value: _formatDateTime(order.createdAt)),
                      _DetailItem(title: '支付状态', value: _getStatusText(order)),
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGreen.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '订单金额',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '¥${order.amount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PaymentButton(
                        order: order,
                        onPayment: (order) {
                          Navigator.pop(context);
                          onPayment(order);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOrderDetails(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _decodeProductName(order.productName),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(order),
                          style: TextStyle(
                            color: _getStatusColor(order),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '订单号',
                            style: TextStyle(
                              color:
                                  CupertinoColors.systemGrey.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.orderNo,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '创建时间',
                            style: TextStyle(
                              color:
                                  CupertinoColors.systemGrey.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatDateTime(order.createdAt),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '金额',
                            style: TextStyle(
                              color:
                                  CupertinoColors.systemGrey.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '¥${order.amount}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ],
                      ),
                      if (order.canPay) ...[
                        const SizedBox(height: 16),
                        PaymentButton(
                          order: order,
                          onPayment: onPayment,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 新增一个用于显示详情项的组件
class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({
    required this.title,
    required this.value,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    ToastUtils.show('已复制');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey5,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: CupertinoColors.systemGrey.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
