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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Provider for the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider for Firebase auth state changes
///
/// Emits the current [User] or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider that returns true if user is authenticated (including guest)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user != null).value ?? false;
});

/// Provider that returns true if user is a registered user (not guest, not anonymous)
final isRegisteredUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => 
    user != null && !user.isAnonymous
  ).value ?? false;
});

/// Provider that returns true if user is in guest mode
final isGuestModeProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => 
    user?.isAnonymous ?? false
  ).value ?? false;
});

/// Provider for the current user's ID (for sync operations)
///
/// Returns null if not authenticated.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// Provider for the current user's email
///
/// Returns null if not authenticated or if anonymous.
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.email;
});
