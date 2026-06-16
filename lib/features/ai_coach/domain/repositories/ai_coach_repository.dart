// lib/features/ai_coach/domain/repositories/ai_coach_repository.dart

import '../models/ai_insight_model.dart';

abstract class AICoachRepository {
  Future<AIInsightModel?> getLatestInsight(String userId);
  Future<AIInsightModel> generateAndSaveInsights(String userId);
  Stream<AIInsightModel?> streamLatestInsight(String userId);
}
