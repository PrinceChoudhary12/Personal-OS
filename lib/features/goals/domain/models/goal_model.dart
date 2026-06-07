// lib/features/goals/domain/models/goal_model.dart
class MilestoneModel {
  final String id;
  final String title;
  final bool isCompleted;

  const MilestoneModel({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  MilestoneModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime targetDate;
  final double progressPercentage;
  final List<MilestoneModel> milestones;
  final String status;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.progressPercentage,
    required this.milestones,
    required this.status,
    required this.createdAt,
  });

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? targetDate,
    double? progressPercentage,
    List<MilestoneModel>? milestones,
    String? status,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      milestones: milestones ?? this.milestones,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
