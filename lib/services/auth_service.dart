import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('Sign up started for $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user profile in Firestore
      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'email': email,
            'displayName': displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'user',
            'profile': {
              'timezone': 'UTC',
              'language': 'en',
              'theme': 'system',
              'notifications_enabled': true,
            },
            'stats': {
              'total_tasks': 0,
              'completed_tasks': 0,
              'total_points': 0,
              'current_streak': 0,
              'longest_streak': 0,
            },
          });
        } catch (e, stack) {
          debugPrint('Failed to create Firestore profile for ${credential.user!.uid}: $e');
          debugPrint(stack.toString());
          rethrow;
        }
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unexpected sign up error: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset password error: ${e.message}');
      rethrow;
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      return doc.data();
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) return;
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(data);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Update user profile error: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) return;
      
      // Delete Firestore data
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      
      // Delete auth account
      await currentUser!.delete();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  // Get error message from FirebaseAuthException
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        final message = e.message?.trim();
        if (message == null || message.isEmpty || message.toLowerCase() == 'error') {
          return 'Firebase auth error (${e.code}). Please try again or contact support.';
        }
        return message;
    }
  }
}
