// lib/features/activities/presentation/providers/activity_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/repositories/activity_repository.dart';

// --- Stream of Activities for current user ---
final activitiesStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(activityRepositoryProvider);
  return repo.streamActivities(user.uid);
});

// --- Activity Controller Provider (CRUD State) ---
final activityControllerProvider =
    AsyncNotifierProvider<ActivityController, void>(ActivityController.new);

class ActivityController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ActivityRepository get _repo => ref.read(activityRepositoryProvider);

  Future<void> addActivity(ActivityModel activity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.createActivity(activity);
      // Trigger streaks and analytics calculations
      await ref.read(streakRepositoryProvider).calculateStreakFromActivities(activity.userId);
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(activity.userId);
    });
  }

  Future<void> editActivity(ActivityModel activity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateActivity(activity);
      // Trigger streaks and analytics calculations
      await ref.read(streakRepositoryProvider).calculateStreakFromActivities(activity.userId);
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(activity.userId);
    });
  }

  Future<void> removeActivity(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final activity = await _repo.getActivityById(id);
      await _repo.deleteActivity(id);
      // Trigger streaks and analytics calculations
      await ref.read(streakRepositoryProvider).calculateStreakFromActivities(activity.userId);
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(activity.userId);
    });
  }
}
