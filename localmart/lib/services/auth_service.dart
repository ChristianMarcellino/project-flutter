import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final AuthService authService = AuthService();

class AuthService extends ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => firebaseAuth.currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  bool _isSigningIn = false;

  AuthService() {
    if (!kIsWeb) {
      _initializeGoogleSignIn();
    }
    firebaseAuth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(clientId: dotenv.env["CLIENT_ID"]);

      _isGoogleSignInInitialized = true;

      print("Google Sign In initialized successfully");
      print("supportsAuthenticate: ${_googleSignIn.supportsAuthenticate()}");
    } catch (e) {
      print("Failed to initialize Google Sign-In: $e");
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (kIsWeb) return;
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (_isSigningIn) {
      throw Exception("Sign-in already in progress");
    }

    _isSigningIn = true;

    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        return await firebaseAuth.signInWithPopup(googleProvider);
      }

      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );

      final String? idToken = account.authentication.idToken;

      final clientAuth = await account.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: clientAuth.accessToken,
      );

      UserCredential userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.additionalUserInfo?.isNewUser == true) {}

      return userCredential;
    } finally {
      _isSigningIn = false;
    }
  }

  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    if (kIsWeb) return null;
    await _ensureGoogleSignInInitialized();

    try {
      final result = _googleSignIn.attemptLightweightAuthentication();
      if (result is Future<GoogleSignInAccount>) {
        return await result;
      } else {
        return result as GoogleSignInAccount;
      }
    } catch (e) {
      print("Silent Sign In Error $e");
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception("Firebase sign-out failed: $e");
    }
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

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
          'emailVerified': false,
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
