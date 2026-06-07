// lib/features/focus_timer/domain/models/focus_session_model.dart
class FocusSessionModel {
  final String id;
  final String userId;
  final String? activityId;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final String outcomeStatus;

  const FocusSessionModel({
    required this.id,
    required this.userId,
    this.activityId,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.outcomeStatus,
  });

  FocusSessionModel copyWith({
    String? id,
    String? userId,
    String? activityId,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    String? outcomeStatus,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      outcomeStatus: outcomeStatus ?? this.outcomeStatus,
    );
  }
}
