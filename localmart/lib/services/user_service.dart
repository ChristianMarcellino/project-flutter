import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return doc.data();
  }

  static Future<void> updateLocation(
    String uid,
    double lat,
    double long, {
    required String locationName,
    required String city,
    required String district,
    required String province,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'latitude': lat,

      'longitude': long,

      'locationName': locationName,

      'city': city,

      'district': district,

      'province': province,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
