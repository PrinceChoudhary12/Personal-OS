// lib/features/notifications/domain/models/reminder_model.dart

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime reminderTime;
  final String type; // 'Goal', 'Streak', 'Focus', 'General', 'AI'
  final bool completed;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.reminderTime,
    required this.type,
    required this.completed,
    required this.createdAt,
  });

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? reminderTime,
    String? type,
    bool? completed,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      type: type ?? this.type,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'reminderTime': reminderTime.toIso8601String(),
      'type': type,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return ReminderModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      reminderTime: parseDate(map['reminderTime']),
      type: map['type'] as String? ?? 'General',
      completed: map['completed'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
