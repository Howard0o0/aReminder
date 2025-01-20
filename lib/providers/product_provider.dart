import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../models/order.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.getProducts();
      if (response.success && response.data != null) {
        _products = response.data!;
        log('获取产品列表成功: ${_products.length}');
        // 按照金额大小升序排序
        _products.sort((a, b) => a.amount.compareTo(b.amount));
      } else {
        _error = response.message ?? '获取产品列表失败';
      }
    } catch (e) {
      log('获取产品列表失败: $e');
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
