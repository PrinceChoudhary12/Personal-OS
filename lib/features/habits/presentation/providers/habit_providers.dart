// lib/features/habits/presentation/providers/habit_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/habit_model.dart';
import '../../domain/repositories/habit_repository.dart';

final habitsStreamProvider = StreamProvider<List<HabitModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }

  final repo = ref.watch(habitRepositoryProvider);
  return repo.streamHabits(user.uid);
});

class HabitController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  HabitController(this._ref) : super(const AsyncValue.data(null));

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  Future<void> addHabit(HabitModel habit) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createHabit(habit);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editHabit(HabitModel habit) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateHabit(habit);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteHabit(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteHabit(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleHabitCompletion(String habitId, String dateStr) async {
    state = const AsyncValue.loading();
    try {
      await _repo.toggleHabitCompletion(habitId, dateStr);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final habitControllerProvider =
    StateNotifierProvider<HabitController, AsyncValue<void>>((ref) {
  return HabitController(ref);
});
