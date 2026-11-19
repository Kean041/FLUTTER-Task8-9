import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final ValueNotifier<bool> googleSignInPending = ValueNotifier(false);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle({String? existingAccountPassword}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    googleSignInPending.value = true;
    try {
      UserCredential userCredential;
      var linkedExistingAccount = false;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'account-exists-with-different-credential') rethrow;

        if (existingAccountPassword == null ||
            existingAccountPassword.isEmpty) {
          throw FirebaseAuthException(
            code: e.code,
            message:
                'This email already has an account. Enter its password above, then try Google sign-in again.',
          );
        }

        final existingAccount = await _auth.signInWithEmailAndPassword(
          email: googleUser.email,
          password: existingAccountPassword,
        );
        final existingUser = existingAccount.user;
        if (existingUser == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Could not sign in to the existing email account.',
          );
        }

        userCredential = await existingUser.linkWithCredential(credential);
        linkedExistingAccount = true;
      }

      if (!linkedExistingAccount &&
          userCredential.additionalUserInfo?.isNewUser != false) {
        try {
          await userCredential.user?.delete();
        } finally {
          await _auth.signOut();
          await _googleSignIn.signOut();
        }
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Please verify your email before logging in.',
        );
      }

      return userCredential.user;
    } finally {
      googleSignInPending.value = false;
    }
  }

  // EMAIL/PASSWORD REGISTER
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
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
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return null;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}
