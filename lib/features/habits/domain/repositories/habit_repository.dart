// lib/features/habits/domain/repositories/habit_repository.dart

import '../models/habit_model.dart';

abstract class HabitRepository {
  Stream<List<HabitModel>> streamHabits(String userId);
  Future<void> createHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
  Future<void> toggleHabitCompletion(String habitId, String dateStr);
}
