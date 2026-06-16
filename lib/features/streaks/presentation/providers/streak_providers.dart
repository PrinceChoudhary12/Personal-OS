// lib/features/streaks/presentation/providers/streak_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/streak_model.dart';
import '../../domain/repositories/streak_repository.dart';

// --- Stream of Streak for the current user ---
final streakStreamProvider = StreamProvider<StreakModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(streakRepositoryProvider);
  return repo.streamStreak(user.uid);
});

// --- Streak Controller Provider ---
final streakControllerProvider =
    AsyncNotifierProvider<StreakController, void>(StreakController.new);

class StreakController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  StreakRepository get _repo => ref.read(streakRepositoryProvider);

  Future<void> initStreak(String userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.initializeStreak(userId));
  }

  Future<void> saveStreak(StreakModel streak) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateStreak(streak));
  }
}
