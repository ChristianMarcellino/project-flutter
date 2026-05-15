
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String sellerPhoneNumber;
  final String sellerName;
  final String title;
  final String description;
  final String category;
  final double price;
  final bool negotiable;
  final List<String> images;
  final String locationName;
  final double latitude;
  final double longitude;
  final List<String> buyerTargets;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;
  final String status;
  final String condition;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhoneNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.negotiable,
    required this.images,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.buyerTargets,
    required this.likesCount,
    this.likedBy = const [],
    required this.commentsCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      sellerName: map["sellerName"] ?? '',
      sellerPhoneNumber: map["sellerPhoneNumber"] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      condition: map['condition'] ?? 'New',
      price: (map['price'] ?? 0).toDouble(),
      negotiable: map['negotiable'] ?? false,
      images: List<String>.from(map['images'] ?? []),
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      buyerTargets: List<String>.from(map['buyerTargets'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      commentsCount: map['commentsCount'] ?? 0,
      status: map['status'] == 'active' ? 'available' : (map['status'] ?? 'available'),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerName' : sellerName,
      'sellerPhoneNumber' : sellerPhoneNumber,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'price': price,
      'negotiable': negotiable,
      'images': images,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'buyerTargets': buyerTargets,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}