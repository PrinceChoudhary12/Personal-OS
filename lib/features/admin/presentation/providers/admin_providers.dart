// lib/features/admin/presentation/providers/admin_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/firestore_admin_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository();
});

// ── Admin Check ────────────────────────────────────────────────────────────
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(firebaseAuthStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.read(adminRepositoryProvider).isAdmin(user.uid);
});

// ── Platform Stats ─────────────────────────────────────────────────────────
final platformStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminRepositoryProvider).getPlatformStats();
});

// ── All Users ──────────────────────────────────────────────────────────────
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

// ── Announcements Stream ───────────────────────────────────────────────────
final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return ref.read(adminRepositoryProvider).streamAnnouncements();
});

// ── Feedback Stream ────────────────────────────────────────────────────────
final feedbackStreamProvider = StreamProvider<List<FeedbackModel>>((ref) {
  return ref.read(adminRepositoryProvider).streamFeedback();
});

// ── Admin Controller ───────────────────────────────────────────────────────
final adminControllerProvider =
    AsyncNotifierProvider<AdminController, void>(AdminController.new);

class AdminController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  Future<void> deleteUser(String uid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteUser(uid));
    ref.invalidate(allUsersProvider);
    ref.invalidate(platformStatsProvider);
  }

  Future<void> resetUserData(String uid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.resetUserData(uid));
    ref.invalidate(allUsersProvider);
    ref.invalidate(platformStatsProvider);
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.createAnnouncement(
      AnnouncementModel(
        id: '',
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    ));
  }

  Future<void> deleteAnnouncement(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteAnnouncement(id));
  }

  Future<void> deleteFeedback(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteFeedback(id));
  }
}
