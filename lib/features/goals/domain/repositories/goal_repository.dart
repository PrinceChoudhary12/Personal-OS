// lib/features/goals/domain/repositories/goal_repository.dart
import '../models/goal_model.dart';

abstract class GoalRepository {
  Stream<List<GoalModel>> streamGoals(String userId);
  Future<GoalModel> getGoalById(String id);
  Future<void> createGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
}
