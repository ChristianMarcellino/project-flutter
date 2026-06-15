import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/app_notif.dart';
import 'package:localmart/models/product.dart';
import 'package:http/http.dart' as http;

class NotifService {
  NotifService._privateConstructor();
  static final NotifService _instance = NotifService._privateConstructor();
  factory NotifService() => _instance;

  static const String baseUrl = 'https://localmart-cloud.vercel.app';

  static final CollectionReference notifsRef = FirebaseFirestore.instance
      .collection(AppConstants.notifsCollection);
  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    String? productId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-to-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': fcmToken,
        'title': title,
        'body': body,
        'productId': productId,
      }),
    );
    print("Notif sent");

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await notifsRef.doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return notifsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<int> getUnreadCount(String userId) {
    return notifsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await notifsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? username,
    String? profilePicture,
    String? productId,
    String? productTitle,
    String? productImage,
  }) async {
    await notifsRef.add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'fromUsername': username,
      'fromProfilePicture': profilePicture,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    });
  }

  Future<void> sendLikeNotification({
    required String sellerId,
    required Product product,
    required String username,
    String? profilePicture,
    required String sellerFcmToken,
  }) async {
    await createNotification(
      userId: sellerId,
      type: "like",
      title: '$username liked your product',
      message: 'Someone is interested in ${product.title}',
      username: username,
      profilePicture: profilePicture,
      productId: product.id,
      productTitle: product.title,
      productImage: product.images.first,
    );
    sendNotification(
      fcmToken: sellerFcmToken,
      title: 'New Like',
      body: '$username liked your product',
      productId: product.id,
    );
  }

  Future<void> sendCommentNotification({
    required String sellerId,
    required Product product,
    required String username,
    String? profilePicture,
    required String sellerFcmToken,
  }) async {
    await createNotification(
      userId: sellerId,
      type: "comment",
      title: '$username commented on your product',
      message: 'Someone commented on ${product.title}',
      username: username,
      profilePicture: profilePicture,
      productId: product.id,
      productTitle: product.title,
      productImage: product.images.first,
    );
    sendNotification(
      fcmToken: sellerFcmToken,
      title: 'New Comment',
      body: '$username commented your product',
      productId: product.id,
    );
  }

  Future<void> sendReplyNotification({
    required String receiverId,
    required Product product,
    required String username,
    String? profilePicture,
    required String sellerFcmToken,
  }) async {
    await createNotification(
      userId: receiverId,
      type: "reply",
      title: '$username replied to your comment',
      message: 'Someone replied to your comment on ${product.title}',
      username: username,
      profilePicture: profilePicture,
      productId: product.id,
      productTitle: product.title,
      productImage: product.images.first,
    );
    sendNotification(
      fcmToken: sellerFcmToken,
      title: 'New Reply',
      body: '$username replied to your comment',
      productId: product.id,
    );
  }
}
