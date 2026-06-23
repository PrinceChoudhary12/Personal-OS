// lib/features/brain_games/presentation/providers/brain_games_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firestore_brain_games_repository.dart';
import '../../domain/models/game_model.dart';
import '../../domain/repositories/brain_games_repository.dart';

// --- Brain Games Repository Provider ---
final brainGamesRepositoryProvider = Provider<BrainGamesRepository>((ref) {
  return FirestoreBrainGamesRepository();
});

// --- Stream of Brain Game Scores for the current user ---
final brainGamesStreamProvider = StreamProvider<List<GameModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    debugPrint('🧠 [BRAIN GAMES PROVIDER] No user authenticated. Returning empty list.');
    return Stream.value([]);
  }

  final repo = ref.watch(brainGamesRepositoryProvider);
  return repo.watchGameScores(user.uid);
});
