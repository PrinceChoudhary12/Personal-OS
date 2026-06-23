// lib/features/scheduler/presentation/providers/scheduler_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/scheduler_model.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../../data/repositories/firestore_scheduler_repository.dart';

final schedulerRepositoryProvider = Provider<SchedulerRepository>((ref) {
  return FirestoreSchedulerRepository();
});

final schedulesStreamProvider = StreamProvider<List<SchedulerModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(schedulerRepositoryProvider);
  return repo.streamSchedules(user.uid);
});

class SchedulerController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SchedulerController(this._ref) : super(const AsyncValue.data(null));

  Future<void> addSchedule(SchedulerModel schedule) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(schedulerRepositoryProvider);
      await repo.createSchedule(schedule);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editSchedule(SchedulerModel schedule) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(schedulerRepositoryProvider);
      await repo.updateSchedule(schedule);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteSchedule(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(schedulerRepositoryProvider);
      await repo.deleteSchedule(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleCompletion(SchedulerModel schedule, bool completed) async {
    final updated = schedule.copyWith(completed: completed);
    await editSchedule(updated);
  }
}

final schedulerControllerProvider =
    StateNotifierProvider<SchedulerController, AsyncValue<void>>((ref) {
  return SchedulerController(ref);
});
