// lib/features/scheduler/domain/models/schedule_model.dart

class ScheduledTask {
  final String id;
  final String title;
  final String category; // Coding, Study, Workout, Deep Work, Break, Custom
  final DateTime startTime;
  final DateTime endTime;
  final bool completed;

  const ScheduledTask({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.completed,
  });

  ScheduledTask copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'completed': completed,
    };
  }

  factory ScheduledTask.fromMap(Map<String, dynamic> map) {
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

    return ScheduledTask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Custom',
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class ScheduleModel {
  final String id; // format: userId_YYYY-MM-DD
  final String userId;
  final DateTime date;
  final List<ScheduledTask> scheduledTasks;
  final bool generatedByAI;
  final String completionStatus; // 'Pending', 'In Progress', 'Completed'
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.scheduledTasks,
    required this.generatedByAI,
    required this.completionStatus,
    required this.createdAt,
  });

  ScheduleModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<ScheduledTask>? scheduledTasks,
    bool? generatedByAI,
    String? completionStatus,
    DateTime? createdAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      scheduledTasks: scheduledTasks ?? this.scheduledTasks,
      generatedByAI: generatedByAI ?? this.generatedByAI,
      completionStatus: completionStatus ?? this.completionStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'scheduledTasks': scheduledTasks.map((t) => t.toMap()).toList(),
      'generatedByAI': generatedByAI,
      'completionStatus': completionStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String docId) {
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

    final tasksList = map['scheduledTasks'] as List? ?? const [];
    final scheduledTasks = tasksList
        .map((t) => ScheduledTask.fromMap(Map<String, dynamic>.from(t)))
        .toList();

    return ScheduleModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      date: parseDate(map['date']),
      scheduledTasks: scheduledTasks,
      generatedByAI: map['generatedByAI'] as bool? ?? false,
      completionStatus: map['completionStatus'] as String? ?? 'Pending',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
