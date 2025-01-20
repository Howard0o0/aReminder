
class Order {
  final String orderNo;
  final String productName;
  final String amount;
  final int payStatus;
  final String? payChannel;
  final DateTime? payTime;
  final DateTime createdAt;
  final String? payUrl;

  Order({
    required this.orderNo,
    required this.productName,
    required this.amount,
    required this.payStatus,
    this.payChannel,
    this.payTime,
    required this.createdAt,
    this.payUrl,
  });

  bool get isValid {
    final now = DateTime.now();
    final validUntil = createdAt.add(const Duration(minutes: 5));
    return now.isBefore(validUntil);
  }

  bool get canPay {
    return payStatus == 0 && isValid;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNo: json['order_no'],
      productName: json['product_name'],
      amount: json['amount'],
      payStatus: json['pay_status'],
      payChannel: json['pay_channel'],
      payTime:
          json['pay_time'] != null ? DateTime.parse(json['pay_time']) : null,
      createdAt: DateTime.parse(json['created_at']),
      payUrl: json['pay_url'],
    );
  }
}