
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
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
  final int commentsCount;
  final String status; 
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.negotiable,
    required this.images,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.buyerTargets,
    required this.likesCount,
    required this.commentsCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      negotiable: map['negotiable'] ?? false,
      images: List<String>.from(map['images'] ?? []),
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      buyerTargets: List<String>.from(map['buyerTargets'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'negotiable': negotiable,
      'images': images,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'buyerTargets': buyerTargets,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}