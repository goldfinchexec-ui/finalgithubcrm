import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight authentication service wrapping FirebaseAuth
class AuthService {
  final FirebaseAuth _auth;

  const AuthService(this._auth);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.signIn error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail({required String email, required String password, String? displayName}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.signUp error: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
      rethrow;
    }
  }
}
