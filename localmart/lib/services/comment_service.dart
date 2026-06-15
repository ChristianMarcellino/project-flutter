import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/notif_service.dart';

class CommentService {
  CommentService._privateConstructor();
  static final CommentService _instance = CommentService._privateConstructor();
  factory CommentService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addComment({
    required Product product,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data()!;

    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .collection(AppConstants.commentsCollection)
        .add({
          'text': text,
          'userId': currentUser.uid,
          'userName': userData["username"],
          'userAvatar': userData['avatar'],
          'createdAt': FieldValue.serverTimestamp(),
          'replyCount': 0,
        });

    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update({'commentsCount': FieldValue.increment(1)});
    if (product.sellerId == currentUser.uid) return;
    final sellerDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(product.sellerId)
        .get();

    final sellerData = sellerDoc.data() ?? {};
    NotifService().sendCommentNotification(
      sellerId: product.sellerId,
      product: product,
      username: userData["username"],
      profilePicture: userData['avatar'],
      sellerFcmToken: sellerData["fcmToken"],
    );
  }

  Future<void> addReply({
    required Product product,
    required String commentId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data()!;

      final commentRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .collection(AppConstants.commentsCollection)
          .doc(commentId);

      await _firestore.runTransaction((tx) async {
        tx.set(commentRef.collection(AppConstants.repliesCollection).doc(), {
          'text': text,
          'userId': currentUser.uid,
          'userName': userData["username"],
          'userAvatar': userData['avatar'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(commentRef, {'replyCount': FieldValue.increment(1)});
      });

      final commentDoc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .collection(AppConstants.commentsCollection)
          .doc(commentId)
          .get();

      final commentData = commentDoc.data();

      if (commentData == null) return;

      final commentOwnerId = commentData['userId'];

      if (commentOwnerId == null) return;

      if (commentOwnerId == currentUser.uid) return;

      final commentOwnerDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(commentOwnerId)
          .get();

      final commentOwnerData = commentOwnerDoc.data();

      if (commentOwnerData == null) return;

      final fcmToken = commentOwnerData['fcmToken'];

      if (fcmToken == null || fcmToken.toString().isEmpty) return;

      await NotifService().sendReplyNotification(
        receiverId: commentOwnerId,
        product: product,
        username: userData['username'] ?? 'User',
        profilePicture: userData['avatar'] ?? '',
        sellerFcmToken: fcmToken,
      );
    } catch (e) {
      print('Reply Error: $e');
    }
  }

  Stream<QuerySnapshot> streamComments(String productId) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .collection(AppConstants.commentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamReplies({
    required String productId,
    required String commentId,
  }) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .collection(AppConstants.commentsCollection)
        .doc(commentId)
        .collection(AppConstants.repliesCollection)
        .orderBy('createdAt')
        .snapshots();
  }
}
