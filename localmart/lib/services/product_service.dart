// product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localmart/models/product.dart';

class ProductService {
  final CollectionReference productsRef = FirebaseFirestore.instance.collection(
    'products',
  );

  Future<void> createProduct(Product product) async {
    await productsRef.doc(product.productId).set(product.toMap());
  }

  Future<Product?> getProductById(String productId) async {
    final doc = await productsRef.doc(productId).get();

    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<Product?> streamProductById(String productId) {
    return productsRef.doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Stream<List<Product>> getAllProducts() {
    return productsRef
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return productsRef
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    updatedData['updatedAt'] = Timestamp.now();

    await productsRef.doc(productId).update(updatedData);
  }

  Future<void> deleteProduct(String productId) async {
    await productsRef.doc(productId).update({
      'status': 'deleted',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markProductSold(String productId) async {
    await productsRef.doc(productId).update({
      'status': 'sold',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> incrementViews(String productId) async {
    await productsRef.doc(productId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }

  Future<void> incrementWhatsappClicks(String productId) async {
    await productsRef.doc(productId).update({
      'whatsappClicks': FieldValue.increment(1),
    });
  }

  Future<void> likeProduct(String productId) async {
    await productsRef.doc(productId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> unlikeProduct(String productId) async {
    await productsRef.doc(productId).update({
      'likesCount': FieldValue.increment(-1),
    });
  }
}
