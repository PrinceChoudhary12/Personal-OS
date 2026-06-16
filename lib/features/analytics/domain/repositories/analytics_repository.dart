// lib/features/analytics/domain/repositories/analytics_repository.dart

import '../models/analytics_model.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsModel?> getAnalytics(String userId);
  Future<void> saveAnalytics(AnalyticsModel analytics);
  Future<AnalyticsModel> calculateAndSaveAnalytics(String userId);
  Stream<AnalyticsModel?> streamAnalytics(String userId);
  Future<void> logEvent(String userId, String eventName, Map<String, dynamic> parameters);
}
