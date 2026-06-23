// lib/features/scheduler/domain/models/scheduler_model.dart

class SchedulerModel {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String priority; // 'Low', 'Medium', 'High'
  final bool completed;
  final DateTime createdAt;

  const SchedulerModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.priority,
    required this.completed,
    required this.createdAt,
  });

  SchedulerModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? priority,
    bool? completed,
    DateTime? createdAt,
  }) {
    return SchedulerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category,
      'priority': priority,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SchedulerModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return SchedulerModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      category: map['category'] as String? ?? 'General',
      priority: map['priority'] as String? ?? 'Medium',
      completed: map['completed'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
