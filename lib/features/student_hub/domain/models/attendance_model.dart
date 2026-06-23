// lib/features/student_hub/domain/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String userId;
  final String subjectId;
  final DateTime date;
  final String status; // 'present', 'absent', 'excused'
  final String? notes;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.date,
    required this.status,
    this.notes,
  });

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    DateTime? date,
    String? status,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return AttendanceModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      date: parseDate(map['date']),
      status: map['status'] as String? ?? 'present',
      notes: map['notes'] as String?,
    );
  }
}
