// lib/features/gamification/domain/repositories/gamification_repository.dart

import '../models/xp_model.dart';

abstract class GamificationRepository {
  Future<XpModel?> getXp(String userId);
  Stream<XpModel?> watchXp(String userId);
  Future<void> saveXp(XpModel xp);
}
