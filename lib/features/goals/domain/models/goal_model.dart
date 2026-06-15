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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory MilestoneModel.fromMap(Map<String, dynamic> map) {
    return MilestoneModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'progressPercentage': progressPercentage,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
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

    final rawMilestones = map['milestones'] as List? ?? const [];
    final List<MilestoneModel> parsedMilestones = rawMilestones
        .map((m) => MilestoneModel.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    return GoalModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      targetDate: parseDate(map['targetDate']),
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      milestones: parsedMilestones,
      status: map['status'] as String? ?? 'Active',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
