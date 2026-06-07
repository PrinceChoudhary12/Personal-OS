// lib/features/analytics/domain/repositories/analytics_repository.dart
abstract class AnalyticsRepository {
  Future<Map<String, dynamic>> getProductivitySummary(String userId, DateTime start, DateTime end);
  Future<void> logEvent(String userId, String eventName, Map<String, dynamic> parameters);
}
