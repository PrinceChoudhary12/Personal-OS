// lib/features/daily_challenges/domain/repositories/challenge_repository.dart

import '../models/challenge_model.dart';

abstract class ChallengeRepository {
  Future<List<ChallengeModel>> getChallenges(String userId);
  Stream<List<ChallengeModel>> watchChallenges(String userId);
  Future<void> saveChallenge(String userId, ChallengeModel challenge);
}
