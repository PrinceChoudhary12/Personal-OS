// lib/features/streaks/domain/repositories/streak_repository.dart
import '../models/streak_model.dart';

abstract class StreakRepository {
  Stream<StreakModel?> streamStreak(String userId);
  Future<StreakModel?> getStreakByUserId(String userId);
  Future<void> updateStreak(StreakModel streak);
  Future<void> initializeStreak(String userId);
}
