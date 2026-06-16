// lib/features/goals/presentation/providers/goals_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/goal_model.dart';

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
