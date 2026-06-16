// lib/features/focus_timer/domain/models/focus_session_model.dart

class FocusSessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String sessionType; // 'Pomodoro', 'Deep Work', 'Custom'
  final bool completed;
  final DateTime createdAt;
  final String? activityId;

  const FocusSessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.sessionType,
    required this.completed,
    required this.createdAt,
    this.activityId,
  });

  FocusSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? sessionType,
    bool? completed,
    DateTime? createdAt,
    String? activityId,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionType: sessionType ?? this.sessionType,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      activityId: activityId ?? this.activityId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'sessionType': sessionType,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'activityId': activityId,
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
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      sessionType: map['sessionType'] as String? ?? 'Pomodoro',
      completed: map['completed'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      activityId: map['activityId'] as String?,
    );
  }
}
