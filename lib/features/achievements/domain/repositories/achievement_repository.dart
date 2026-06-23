// lib/features/achievements/domain/repositories/achievement_repository.dart

import '../models/achievement_model.dart';

abstract class AchievementRepository {
  Future<List<AchievementModel>> getAchievements(String userId);
  Stream<List<AchievementModel>> watchAchievements(String userId);
  Future<void> saveAchievement(String userId, AchievementModel achievement);
}
