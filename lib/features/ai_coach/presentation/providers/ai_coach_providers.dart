// lib/features/ai_coach/presentation/providers/ai_coach_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/ai_insight_model.dart';
import '../../domain/repositories/ai_coach_repository.dart';

final aiInsightStreamProvider = StreamProvider<AIInsightModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final AICoachRepository repo = ref.watch(aiCoachRepositoryProvider);
  return repo.streamLatestInsight(user.uid);
});

class AICoachController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AICoachController(this._ref) : super(const AsyncValue.data(null));

  Future<void> syncInsights() async {
    final authState = _ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(aiCoachRepositoryProvider);
      await repo.generateAndSaveInsights(user.uid);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final aiCoachControllerProvider =
    StateNotifierProvider<AICoachController, AsyncValue<void>>((ref) {
  return AICoachController(ref);
});
