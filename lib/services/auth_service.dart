import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _shared = AuthService();
  static AuthService get instance => _shared;

  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  User? get currentUser => _isFirebaseInitialized ? _auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;
  
  Stream<User?> get authStateChanges => _isFirebaseInitialized 
      ? _auth.authStateChanges() 
      : Stream.value(null);

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
          final userRef = _firestore.collection('users').doc(credential.user!.uid);
          final userDoc = await userRef.get();
          
          if (!userDoc.exists) {
            await userRef.set({
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
              'gamification': {
                'currentMonthXP': 0,
                'currentRank': 'Aether',
                'totalTasksCompleted': 0,
                'currentStreak': 0,
                'longestStreak': 0,
                'dailyCategories': {},
                'dailyTasksByCategory': {},
                'tasksByDifficulty': {},
                'tasksByPriority': {},
                'tasksByCategory': {},
                'longTaskCount': 0,
                'prestigeRanks': {
                  'Aether': 0,
                  'Vanguard': 0,
                  'Champion': 0,
                  'Sentinel': 0,
                  'Gladiator': 0,
                  'Legion': 0,
                  'Imperium': 0,
                },
                'achievementsUnlocked': [],
                'lastTaskCompletedAt': null,
                'lastMonthlyReset': FieldValue.serverTimestamp(),
              },
            });
            debugPrint('New Firestore profile created for ${credential.user!.uid}');
          } else {
            debugPrint('Firestore profile already exists for ${credential.user!.uid}, skipping initialization.');
          }
        } catch (e, stack) {
          debugPrint('Failed to handle Firestore profile for ${credential.user!.uid}: $e');
          debugPrint(stack.toString());
          // We don't rethrow here because the Auth account is already created
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

  // Pre-defined Superadmin credentials (should be stored securely, e.g., in environment variables)
  static const String _superAdminEmail = 'superadmin@taskcue.com';
  static const String _superAdminPassword = 'superadmin123';

  static String get superAdminEmail => _superAdminEmail;

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

      // Update last active and check for Superadmin override
      if (credential.user != null) {
        final userRef = _firestore.collection('users').doc(credential.user!.uid);
        
        // Superadmin check: If credentials match, elevate role
        if (email == _superAdminEmail && password == _superAdminPassword) {
          await userRef.update({
            'lastActive': FieldValue.serverTimestamp(),
            'role': 'superadmin', // Elevate to superadmin
          });
        } else {
          await userRef.update({
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle non-Dart exceptions specifically for Web compatibility
      debugPrint('Unexpected sign in error: ${e.toString()}');
      throw Exception(e.toString());
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
          .get(const GetOptions(source: Source.serverAndCache));
      
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
  static String getErrorMessage(dynamic e) {
    if (e is! FirebaseAuthException) {
      return 'An unexpected error occurred. Please try again.';
    }
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

  Future<void> initialize() async {
    try {
      // Check if Firebase is initialized
      _authInstance = FirebaseAuth.instance;
      _firestoreInstance = FirebaseFirestore.instance;
      _isFirebaseInitialized = true;
      debugPrint('AuthService: Firebase confirmed initialized');
    } catch (e) {
      debugPrint('AuthService: Firebase not initialized or unavailable: $e');
      _isFirebaseInitialized = false;
    }

    if (_isFirebaseInitialized && currentUser != null) {
      await getUserProfile();
    }
  }

  Future<bool> checkAdminStatus() async {
    final profile = await getUserProfile();
    if (profile == null) return false;

    final role = (profile['role'] as String?)?.toLowerCase();
    return role == 'admin' || role == 'superadmin';
  }
}

