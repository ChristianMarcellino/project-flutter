import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? username;
  final String? profilePicture;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final bool isRead;
  final Timestamp createdAt;
  final Timestamp? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.username,
    this.profilePicture,
    this.productId,
    this.productTitle,
    this.productImage,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      username: map['fromUsername'],
      profilePicture: map['fromProfilePicture'],
      productId: map['productId'],
      productTitle: map['productTitle'],
      productImage: map['productImage'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      readAt: map['readAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'fromUsername': username,
      'fromProfilePicture': profilePicture,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'isRead': isRead,
      'createdAt': createdAt,
      'readAt': readAt,
    };
  }
}
