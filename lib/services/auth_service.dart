// Copyright 2026 PneumaGe Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:firebase_auth/firebase_auth.dart';

/// Service for Firebase Authentication operations.
///
/// Handles user registration, login, guest mode, and sign out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current user's ID (null if not authenticated)
  String? getCurrentUserId() => _auth.currentUser?.uid;

  /// Check if current user is a guest (anonymous)
  bool isGuest() => _auth.currentUser?.isAnonymous ?? false;

  /// Check if user is authenticated (including guest)
  bool isAuthenticated() => _auth.currentUser != null;

  /// Check if user is authenticated and not a guest
  bool isRegisteredUser() => 
      _auth.currentUser != null && !(_auth.currentUser?.isAnonymous ?? true);

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password
  ///
  /// Throws [FirebaseAuthException] on error:
  /// - `email-already-in-use`: Email already registered
  /// - `invalid-email`: Email format invalid
  /// - `weak-password`: Password too weak (< 6 chars)
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign in with email and password
  ///
  /// Throws [FirebaseAuthException] on error:
  /// - `user-not-found`: No account with this email
  /// - `wrong-password`: Incorrect password
  /// - `invalid-email`: Email format invalid
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign in anonymously as a guest
  ///
  /// Guest users have limited functionality:
  /// - Can connect to BLE devices
  /// - Can record measurements locally
  /// - Cannot sync to Firebase cloud
  Future<UserCredential> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Map Firebase auth exceptions to user-friendly messages
  Exception _mapAuthException(FirebaseAuthException e) {
    final message = _getErrorMessage(e.code);
    return Exception(message);
  }

  /// Get user-friendly error messages for auth error codes
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already registered. Try logging in instead.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Sign in method not enabled. Contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication error: $code';
    }
  }
}
