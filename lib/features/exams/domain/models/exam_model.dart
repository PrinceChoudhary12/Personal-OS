// lib/features/exams/domain/models/exam_model.dart

class ExamModel {
  final String id;
  final String userId;
  final String subject;
  final DateTime examDate;
  final String priority; // 'High', 'Medium', 'Low'
  final String syllabus;
  final int dailyStudyGoalMinutes;
  final int weeklyStudyGoalMinutes;
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.examDate,
    required this.priority,
    required this.syllabus,
    required this.dailyStudyGoalMinutes,
    required this.weeklyStudyGoalMinutes,
    required this.createdAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate.year, examDate.month, examDate.day);
    return target.difference(today).inDays;
  }

  ExamModel copyWith({
    String? id,
    String? userId,
    String? subject,
    DateTime? examDate,
    String? priority,
    String? syllabus,
    int? dailyStudyGoalMinutes,
    int? weeklyStudyGoalMinutes,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      priority: priority ?? this.priority,
      syllabus: syllabus ?? this.syllabus,
      dailyStudyGoalMinutes: dailyStudyGoalMinutes ?? this.dailyStudyGoalMinutes,
      weeklyStudyGoalMinutes: weeklyStudyGoalMinutes ?? this.weeklyStudyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'priority': priority,
      'syllabus': syllabus,
      'dailyStudyGoalMinutes': dailyStudyGoalMinutes,
      'weeklyStudyGoalMinutes': weeklyStudyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return ExamModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      examDate: parseDate(map['examDate']),
      priority: map['priority'] as String? ?? 'Medium',
      syllabus: map['syllabus'] as String? ?? '',
      dailyStudyGoalMinutes: map['dailyStudyGoalMinutes'] as int? ?? 60,
      weeklyStudyGoalMinutes: map['weeklyStudyGoalMinutes'] as int? ?? 300,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
