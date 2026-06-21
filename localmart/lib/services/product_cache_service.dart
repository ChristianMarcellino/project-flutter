import 'package:localmart/models/product.dart';
import 'package:localmart/services/product_service.dart';

class ProductCacheService {
  ProductCacheService._();

  static final ProductCacheService instance = ProductCacheService._();

  List<Product>? _cache;
  Stream<List<Product>>? _stream;

  List<Product>? get cache => _cache;

  Stream<List<Product>> get stream {
    _stream ??= ProductService().getAllProducts().map((data) {
      _cache = data;
      return data;
    });

    return _stream!;
  }

  void clearCache() {
    _cache = null;
    _stream = null;
  }
}
