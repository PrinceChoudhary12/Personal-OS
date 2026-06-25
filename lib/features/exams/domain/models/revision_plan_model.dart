// lib/features/exams/domain/models/revision_plan_model.dart

class RevisionPlanModel {
  final String id;
  final String examId;
  final String userId;
  final String topicName;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RevisionPlanModel({
    required this.id,
    required this.examId,
    required this.userId,
    required this.topicName,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  RevisionPlanModel copyWith({
    String? id,
    String? examId,
    String? userId,
    String? topicName,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RevisionPlanModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      userId: userId ?? this.userId,
      topicName: topicName ?? this.topicName,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'userId': userId,
      'topicName': topicName,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RevisionPlanModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return RevisionPlanModel(
      id: docId,
      examId: map['examId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      topicName: map['topicName'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
