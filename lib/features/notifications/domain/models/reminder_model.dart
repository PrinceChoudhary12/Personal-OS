// lib/features/notifications/domain/models/reminder_model.dart

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type; // 'Goal', 'Focus', 'Activity', 'AI', 'General'
  final DateTime triggerTime;
  final String repeatType; // 'None', 'Daily', 'Weekly'
  final bool isEnabled;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.triggerTime,
    required this.repeatType,
    required this.isEnabled,
    required this.createdAt,
  });

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    DateTime? triggerTime,
    String? repeatType,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      triggerTime: triggerTime ?? this.triggerTime,
      repeatType: repeatType ?? this.repeatType,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'triggerTime': triggerTime.toIso8601String(),
      'repeatType': repeatType,
      'isEnabled': isEnabled,
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
      type: map['type'] as String? ?? 'General',
      triggerTime: parseDate(map['triggerTime']),
      repeatType: map['repeatType'] as String? ?? 'None',
      isEnabled: map['isEnabled'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
