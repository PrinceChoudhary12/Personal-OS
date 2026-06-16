// lib/features/auth/presentation/providers/auth_providers.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── 1. Raw Firebase auth-state stream ────────────────────────────────────────
// Used by the router redirect to cheaply know if a user is signed in.
final firebaseAuthStateProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges().map((user) {
    debugPrint('🔥 AUTH USER: ${user?.email}');
    return user;
  });
});

// ─── 2. AuthRepository — concrete Firebase implementation ─────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// ─── 3. Domain UserModel stream (mapped through repository) ───────────────────
final userModelStreamProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChanged;
});

// ─── 4. AuthController — handles signIn / signUp / signOut ────────────────────
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmailAndPassword(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signOut());
  }
}
