// lib/features/student_hub/domain/models/assignment_model.dart

class AssignmentModel {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // 'Pending', 'Submitted', 'Graded'
  final String? grade;
  final double? score;
  final double? maxScore;
  final DateTime createdAt;

  const AssignmentModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.grade,
    this.score,
    this.maxScore,
    required this.createdAt,
  });

  AssignmentModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? grade,
    double? score,
    double? maxScore,
    DateTime? createdAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'grade': grade,
      'score': score,
      'maxScore': maxScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return AssignmentModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: parseDate(map['dueDate']),
      status: map['status'] as String? ?? 'Pending',
      grade: map['grade'] as String?,
      score: (map['score'] as num?)?.toDouble(),
      maxScore: (map['maxScore'] as num?)?.toDouble(),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
