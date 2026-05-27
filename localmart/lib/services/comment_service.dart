import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localmart/constants.dart';

class CommentService {
  CommentService._privateConstructor();
  static final CommentService _instance = CommentService._privateConstructor();
  factory CommentService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addComment({
    required String productId,
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
        .doc(productId)
        .collection(AppConstants.commentsCollection)
        .add({
          'text': text,
          'userId': currentUser.uid,
          'userName': userData["username"],
          'userAvatar': userData['avatar'],
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update({
          'commentsCount': FieldValue.increment(1),
        });
  }

  Future<void> addReply({
    required String productId,
    required String commentId,
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
        .doc(productId)
        .collection(AppConstants.commentsCollection)
        .doc(commentId)
        .collection(AppConstants.repliesCollection)
        .add({
          'text': text,
          'userId': currentUser.uid,
          'userName': userData["username"],
          'userAvatar': userData['avatar'],
          'createdAt': FieldValue.serverTimestamp(),
        });
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
