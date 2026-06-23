// lib/features/brain_games/domain/repositories/brain_games_repository.dart

import '../models/game_model.dart';

abstract class BrainGamesRepository {
  Future<GameModel?> getGameScore(String userId, String gameType);
  Stream<List<GameModel>> watchGameScores(String userId);
  Future<void> saveGameScore(GameModel model);
  Future<void> recordGamePlay(String userId, String gameType, double score);
}
