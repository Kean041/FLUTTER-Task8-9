import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );
      return userCredential.user;
    }
    final UserCredential userCredential = await _auth.signInWithProvider(
      googleProvider,
    );
    return userCredential.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<bool> isEmailVerified(User user) async {
    await user.reload();
    final currentUser = _auth.currentUser;
    return currentUser != null && hasVerifiedEmail(currentUser);
  }

  bool hasVerifiedEmail(User user) {
    return user.emailVerified ||
        user.providerData.any(
          (profile) => profile.providerId == GoogleAuthProvider.PROVIDER_ID,
        );
  }

  Future<void> sendEmailVerification(User user) {
    return user.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.userChanges();
}
