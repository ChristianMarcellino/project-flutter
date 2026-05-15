import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localmart/models/product.dart';

class ProductService {
  static final CollectionReference productsRef =
      FirebaseFirestore.instance.collection('products');

  Stream<Product?> streamProductById(String id) {
    return productsRef.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<void> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> images,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    await productsRef.add({
      'sellerId': user.uid,
      'sellerName': userData['username'] ?? user.displayName ?? 'User',
      'sellerPhoneNumber': userData['phoneNumber'] ?? '',
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'price': price,
      'negotiable': true,
      'images': images,
      'locationName': userData['locationName'] ?? 'Unknown',
      'latitude': userData['latitude'] ?? 0.0,
      'longitude': userData['longitude'] ?? 0.0,
      'status': 'available',
      'likesCount': 0,
      'likedBy': [],
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Product>> getAllProducts() {
    return productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return productsRef
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    updatedData['updatedAt'] = FieldValue.serverTimestamp();
    await productsRef.doc(productId).update(updatedData);
  }

  Future<void> markProductSold(String productId) async {
    await productsRef.doc(productId).update({
      'status': 'sold',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String productId, String userId) async {
    final docRef = productsRef.doc(productId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final alreadyLiked = likedBy.contains(userId);

      if (alreadyLiked) {
        likedBy.remove(userId);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }
}
