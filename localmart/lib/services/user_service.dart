import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localmart/constants.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
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
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'latitude': lat,
      'longitude': long,
      'locationName': locationName,
      'city': city,
      'district': district,
      'province': province,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateToken(String uid, String token) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'uid': doc.id};
          }).toList(),
        );
  }

  static Future<void> updateProfile(
    String uid, {
    String? username,
    String? bio,
    String? phoneNumber,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}
