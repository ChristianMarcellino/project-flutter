import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addComment({
    required String productId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data()!;

    await _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .add({
          'text': text,
          'userId': currentUser.uid,
          'userName': userData["username"],
          'userAvatar': userData['avatar'],
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('products').doc(productId).update({
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
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data()!;

    await _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
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
        .collection('products')
        .doc(productId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamReplies({
    required String productId,
    required String commentId,
  }) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots();
  }
}
