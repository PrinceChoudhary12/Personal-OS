// lib/features/student_hub/domain/models/subject_model.dart

class SubjectModel {
  final String id;
  final String userId;
  final String name;
  final String code;
  final double credits;
  final String? grade;
  final double? gradePoint;
  final int semester;
  final bool isCompleted;
  final DateTime createdAt;

  const SubjectModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.code,
    required this.credits,
    this.grade,
    this.gradePoint,
    required this.semester,
    required this.isCompleted,
    required this.createdAt,
  });

  SubjectModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? code,
    double? credits,
    String? grade,
    double? gradePoint,
    int? semester,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      grade: grade ?? this.grade,
      gradePoint: gradePoint ?? this.gradePoint,
      semester: semester ?? this.semester,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'code': code,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'semester': semester,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return SubjectModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      credits: (map['credits'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] as String?,
      gradePoint: (map['gradePoint'] as num?)?.toDouble(),
      semester: map['semester'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
