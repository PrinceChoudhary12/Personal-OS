// lib/features/student_hub/domain/models/placement_model.dart

class PlacementModel {
  final String id;
  final String userId;
  final String company;
  final String role;
  final String status; // 'Wishlist', 'Applied', 'Assessment', 'Interviewing', 'Offered', 'Rejected'
  final String? salary;
  final String? location;
  final String? notes;
  final DateTime? appliedDate;
  final DateTime? interviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlacementModel({
    required this.id,
    required this.userId,
    required this.company,
    required this.role,
    required this.status,
    this.salary,
    this.location,
    this.notes,
    this.appliedDate,
    this.interviewDate,
    required this.createdAt,
    required this.updatedAt,
  });

  PlacementModel copyWith({
    String? id,
    String? userId,
    String? company,
    String? role,
    String? status,
    String? salary,
    String? location,
    String? notes,
    DateTime? appliedDate,
    DateTime? interviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlacementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      company: company ?? this.company,
      role: role ?? this.role,
      status: status ?? this.status,
      salary: salary ?? this.salary,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      appliedDate: appliedDate ?? this.appliedDate,
      interviewDate: interviewDate ?? this.interviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'company': company,
      'role': role,
      'status': status,
      'salary': salary,
      'location': location,
      'notes': notes,
      'appliedDate': appliedDate?.toIso8601String(),
      'interviewDate': interviewDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlacementModel.fromMap(Map<String, dynamic> map, String docId) {
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

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        return DateTime.tryParse(val);
      }
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return PlacementModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      company: map['company'] as String? ?? '',
      role: map['role'] as String? ?? '',
      status: map['status'] as String? ?? 'Wishlist',
      salary: map['salary'] as String?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      appliedDate: parseNullableDate(map['appliedDate']),
      interviewDate: parseNullableDate(map['interviewDate']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
    );
  }
}
