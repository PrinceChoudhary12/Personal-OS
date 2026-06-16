// lib/features/focus_timer/domain/repositories/focus_repository.dart

import '../models/focus_session_model.dart';

abstract class FocusRepository {
  Future<String> createSession(FocusSessionModel session);
  Future<void> endSession(
    String sessionId, {
    required bool completed,
    required DateTime endTime,
    required int durationMinutes,
  });
  Stream<List<FocusSessionModel>> streamSessions(String userId);
  Future<void> deleteSession(String sessionId);
}
