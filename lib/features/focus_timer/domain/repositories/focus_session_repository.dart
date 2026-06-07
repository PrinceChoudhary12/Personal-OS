// lib/features/focus_timer/domain/repositories/focus_session_repository.dart
import '../models/focus_session_model.dart';

abstract class FocusSessionRepository {
  Stream<List<FocusSessionModel>> streamFocusSessions(String userId);
  Future<void> logFocusSession(FocusSessionModel session);
  Future<List<FocusSessionModel>> getSessionsInTimeRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  });
  Future<void> deleteFocusSession(String id);
}
