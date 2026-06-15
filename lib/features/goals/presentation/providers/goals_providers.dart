// lib/features/goals/presentation/providers/goals_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firestore_goal_repository.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';

// --- Goal Repository Provider ---
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirestoreGoalRepository();
});

// --- Stream of Goals for current user ---
final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(goalRepositoryProvider);
  return repo.streamGoals(user.uid);
});
