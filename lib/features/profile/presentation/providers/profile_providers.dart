// lib/features/profile/presentation/providers/profile_providers.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

// --- Profile Repository Provider ---
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepository();
});

// --- User Profile Stream Provider ---
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchProfile(user.uid);
});

// --- Profile Controller Provider (For Editing/Saving State) ---
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.saveProfile(profile);

      // Keep Firebase Auth displayName in sync with Firestore profile displayName
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.displayName != profile.displayName) {
        await fbUser.updateDisplayName(profile.displayName);
        await fbUser.reload();
      }
    });
  }
}
