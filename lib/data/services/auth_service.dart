import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/error_message_utils.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Service handling Firebase Authentication and user document management
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        ErrorMessageUtils.map(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AppException('Failed to sign in', originalError: e);
    }
  }

  /// Registers a new user and creates their associated Firestore document
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String barangay,
    required String phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'barangay': barangay,
          'phoneNumber': phone,
          'role': 'resident',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        ErrorMessageUtils.map(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AppException('Failed to create account', originalError: e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppException('Failed to sign out', originalError: e);
    }
  }

  /// Sends a password reset email via Firebase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        ErrorMessageUtils.map(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to send reset email', originalError: e);
    }
  }
}

final userRoleProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        return data?['role'] as String? ?? 'resident';
      });
});
