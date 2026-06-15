// lib/features/activities/presentation/providers/activity_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firestore_activity_repository.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/repositories/activity_repository.dart';

// --- Activity Repository Provider ---
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FirestoreActivityRepository();
});

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
    state = await AsyncValue.guard(() => _repo.createActivity(activity));
  }

  Future<void> editActivity(ActivityModel activity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateActivity(activity));
  }

  Future<void> removeActivity(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteActivity(id));
  }
}
