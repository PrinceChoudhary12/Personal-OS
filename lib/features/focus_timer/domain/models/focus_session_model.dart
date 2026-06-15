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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityId': activityId,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'outcomeStatus': outcomeStatus,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return FocusSessionModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      activityId: map['activityId'] as String?,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      outcomeStatus: map['outcomeStatus'] as String? ?? 'Completed',
    );
  }
}
