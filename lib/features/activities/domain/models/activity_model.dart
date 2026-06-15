// lib/features/activities/domain/models/activity_model.dart

class ActivityModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String notes;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // In minutes
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.notes,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.createdAt,
  });

  ActivityModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'notes': notes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return ActivityModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Custom',
      notes: map['notes'] as String? ?? '',
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      duration: map['duration'] as int? ?? 0,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
