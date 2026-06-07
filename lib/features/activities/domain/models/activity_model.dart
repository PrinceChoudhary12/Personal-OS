// lib/features/activities/domain/models/activity_model.dart
class ActivityModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
  });

  ActivityModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
