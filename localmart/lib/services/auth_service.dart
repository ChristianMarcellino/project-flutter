import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:localmart/constants.dart';

final AuthService authService = AuthService();

class AuthService extends ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  AuthService() {
    firebaseAuth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'email': email,
              'username': username,
              'phoneNumber': phoneNumber,
              'createdAt': FieldValue.serverTimestamp(),
              'provider': 'email',
              'bio': '',
              'avatar': '',
            });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
      throw Exception(e.message ?? 'Signup failed');
    } catch (e) {
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
      throw Exception(e.toString());
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Failed to send password reset email.");
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
