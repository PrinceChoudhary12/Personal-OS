// lib/features/scheduler/presentation/providers/schedule_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/schedule_model.dart';
import '../../domain/repositories/schedule_repository.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final scheduleStreamProvider = StreamProvider<ScheduleModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final selectedDate = ref.watch(selectedDateProvider);
  final ScheduleRepository repo = ref.watch(scheduleRepositoryProvider);
  return repo.streamSchedule(user.uid, selectedDate);
});

final todayScheduleStreamProvider = StreamProvider<ScheduleModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final ScheduleRepository repo = ref.watch(scheduleRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return repo.streamSchedule(user.uid, today);
});

class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ScheduleController(this._ref) : super(const AsyncValue.data(null));

  Future<void> generateDayPlan(DateTime date) async {
    final authState = _ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(scheduleRepositoryProvider);
      await repo.generateSchedule(user.uid, date);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleTask(DateTime date, String taskId, bool completed) async {
    final authState = _ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(scheduleRepositoryProvider);
      await repo.updateTaskCompletion(user.uid, date, taskId, completed);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> saveCustomSchedule(ScheduleModel schedule) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(scheduleRepositoryProvider);
      await repo.saveSchedule(schedule);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final scheduleControllerProvider =
    StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
  return ScheduleController(ref);
});
