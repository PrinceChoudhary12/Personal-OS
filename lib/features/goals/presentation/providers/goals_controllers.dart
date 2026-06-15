// lib/features/goals/presentation/providers/goals_controllers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/goal_model.dart';
import 'goals_providers.dart';

class GoalsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle (AsyncData(null))
  }

  Future<bool> createGoal(GoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.createGoal(goal);
      state = const AsyncValue.data(null);
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
      await repo.deleteGoal(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleMilestone(GoalModel goal, String milestoneId, bool isCompleted) async {
    // Toggling a milestone requires recalculating progress percentage and saving
    final updatedMilestones = goal.milestones.map((m) {
      if (m.id == milestoneId) {
        return m.copyWith(isCompleted: isCompleted);
      }
      return m;
    }).toList();

    final completedCount = updatedMilestones.where((m) => m.isCompleted).length;
    final totalCount = updatedMilestones.length;
    final double newProgress = totalCount > 0 
        ? (completedCount / totalCount * 100.0) 
        : 0.0;

    final String newStatus = newProgress >= 100.0 ? 'Completed' : 'Active';

    final updatedGoal = goal.copyWith(
      milestones: updatedMilestones,
      progressPercentage: newProgress,
      status: newStatus,
    );

    // Perform database update
    return updateGoal(updatedGoal);
  }
}

final goalsControllerProvider = AutoDisposeAsyncNotifierProvider<GoalsController, void>(() {
  return GoalsController();
});
