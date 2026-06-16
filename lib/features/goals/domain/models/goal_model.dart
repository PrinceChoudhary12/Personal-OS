// lib/features/goals/domain/models/goal_model.dart

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final double targetHours;
  final double completedHours;
  final double progressPercentage;
  final bool isCompleted;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.targetHours,
    required this.completedHours,
    required this.progressPercentage,
    required this.isCompleted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    double? targetHours,
    double? completedHours,
    double? progressPercentage,
    bool? isCompleted,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetHours: targetHours ?? this.targetHours,
      completedHours: completedHours ?? this.completedHours,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'targetHours': targetHours,
      'completedHours': completedHours,
      'progressPercentage': progressPercentage,
      'isCompleted': isCompleted,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return GoalModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Custom',
      targetHours: (map['targetHours'] as num?)?.toDouble() ?? 0.0,
      completedHours: (map['completedHours'] as num?)?.toDouble() ?? 0.0,
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      status: map['status'] as String? ?? 'Active',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

extension GoalListAnalytics on List<GoalModel> {
  double get totalGoalHours => fold(0.0, (sum, goal) => sum + goal.targetHours);
  double get completedGoalHours => fold(0.0, (sum, goal) => sum + goal.completedHours);
  double get completionRate {
    if (isEmpty) return 0.0;
    final completedCount = where((goal) => goal.isCompleted).length;
    return (completedCount / length) * 100.0;
  }
}
