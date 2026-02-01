import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/exceptions/app_exception.dart';
import '../shared/utils/error_message_utils.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Check if user exists in our database first
      // This is needed because Firebase sendPasswordResetEmail doesn't always throw
      // for non-existent emails for security reasons (to prevent enumeration).
      // However, the client specifically requested this check.
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw AuthException(
          'No user found with this email.',
          code: 'user-not-found',
        );
      }

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
