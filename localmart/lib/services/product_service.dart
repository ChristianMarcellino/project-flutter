import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/notif_service.dart';

class ProductService {
  ProductService._privateConstructor();
  static final ProductService _instance = ProductService._privateConstructor();
  factory ProductService() => _instance;

  static final CollectionReference productsRef = FirebaseFirestore.instance
      .collection(AppConstants.productsCollection);

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
    required List<String> images,
  }) async {
    final user = authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    final userDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
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
    return productsRef.where("status", isEqualTo: "available").snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Stream<List<Product>> getSomeProductsBySeller(String sellerId) {
    return productsRef
        .where('sellerId', isEqualTo: sellerId)
        .limit(6)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  Stream<List<Product>> getAllProductsBySeller(String sellerId) {
    return productsRef.where('sellerId', isEqualTo: sellerId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Future<void> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? status,
  }) async {
    final user = authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = await productsRef.doc(productId).get();

    if (!doc.exists) throw Exception("Product not found");

    final data = doc.data() as Map<String, dynamic>;

    if (data['sellerId'] != user.uid) {
      throw Exception("Only seller can update product");
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (category != null) updates['category'] = category;
    if (status != null) updates['status'] = status;

    await productsRef.doc(productId).update(updates);
  }

  Future<void> deleteProduct(String productId) async {
    final user = authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = await productsRef.doc(productId).get();

    if (!doc.exists) throw Exception("Product not found");

    final data = doc.data() as Map<String, dynamic>;

    if (data['sellerId'] != user.uid) {
      throw Exception("Only seller can delete product");
    }

    await productsRef.doc(productId).delete();
  }

  Future<void> toggleLike({
    required Product product,
    required String userId,
    required String username,
    String? profilePicture,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;
    final docRef = productsRef.doc(product.id);

    bool shouldNotify = false;

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

        shouldNotify = true;

        transaction.update(docRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1),
        });
      }
    });
    if (product.sellerId == currentUser.uid) return;

    if (!shouldNotify) return;

    if (product.sellerId == userId) return;

    final sellerDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(product.sellerId)
        .get();

    final sellerData = sellerDoc.data() ?? {};

    await NotifService().sendLikeNotification(
      product: product,
      sellerId: product.sellerId,
      username: username,
      profilePicture: profilePicture,
      sellerFcmToken: sellerData['fcmToken'] ?? '',
    );
  }
}
