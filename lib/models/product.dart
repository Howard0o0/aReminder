class Product {
  final String productId;
  final String productName;
  final int productType; // 1: 周会员 2: 年会员 3: 永久会员
  final double amount;
  final int duration;

  Product({
    required this.productId,
    required this.productName,
    required this.productType,
    required this.amount,
    required this.duration,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      productName: json['product_name'],
      productType: json['product_type'],
      amount: double.parse(json['amount']),
      duration: json['duration'],
    );
  }
}
