// lib/features/goals/presentation/providers/goals_controllers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/goal_model.dart';

class GoalsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  Future<bool> createGoal(GoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.createGoal(goal);
      state = const AsyncValue.data(null);
      // Trigger analytics calculations
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(goal.userId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateGoal(GoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.updateGoal(goal);
      state = const AsyncValue.data(null);
      // Trigger analytics calculations
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(goal.userId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(goalRepositoryProvider);
      final goal = await repo.getGoalById(id);
      await repo.deleteGoal(id);
      state = const AsyncValue.data(null);
      // Trigger analytics calculations
      await ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(goal.userId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateGoalProgress(GoalModel goal, double completedHours) async {
    final progress = goal.targetHours > 0
        ? (completedHours / goal.targetHours * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final isCompleted = progress >= 100.0;

    final updatedGoal = goal.copyWith(
      completedHours: completedHours,
      progressPercentage: progress,
      isCompleted: isCompleted,
      status: isCompleted ? 'Completed' : goal.status == 'Completed' ? 'Active' : goal.status,
      updatedAt: DateTime.now(),
    );

    return updateGoal(updatedGoal);
  }

  Future<bool> markGoalComplete(GoalModel goal) async {
    final updatedGoal = goal.copyWith(
      completedHours: goal.targetHours,
      progressPercentage: 100.0,
      isCompleted: true,
      status: 'Completed',
      updatedAt: DateTime.now(),
    );

    return updateGoal(updatedGoal);
  }
}

final goalsControllerProvider =
    AutoDisposeAsyncNotifierProvider<GoalsController, void>(() {
  return GoalsController();
});
