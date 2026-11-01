import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  FirebaseAuthService._internal();
  static final FirebaseAuthService instance = FirebaseAuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Sign up a new shop owner with email and password
  Future<UserCredential> signUpWithOwner({
    required String email,
    required String password,
    required String shopName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    // Generate clean shopId from UID
    final cleanSuffix = uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();
    final shopId = 'SHOP-SYNC-$cleanSuffix';

    // Persist shop document in Firestore & seed sample catalog
    await FirestoreService.instance.createShop(
      shopId: shopId,
      shopName: shopName,
      ownerEmail: email.trim(),
    );

    // Save owner profile
    await FirestoreService.instance.saveUserProfile(
      uid: uid,
      email: email.trim(),
      role: 'owner',
      shopId: shopId,
      name: shopName,
    );

    return cred;
  }

  /// Sign in existing owner or staff member
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out current Firebase session
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('FirebaseAuthService: signOut notice: $e');
    }
  }

  /// Translates Firebase auth exceptions to user-friendly messages
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email address is already in use by another account.';
        case 'invalid-email':
          return 'The email address format is not valid.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled in Firebase Console.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid credentials. Please verify your email and password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'An authentication error occurred. Please try again.';
      }
    }
    return error?.toString() ?? 'An unknown error occurred.';
  }
}
