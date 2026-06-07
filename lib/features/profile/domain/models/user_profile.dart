// lib/features/profile/domain/models/user_profile.dart

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String university;
  final String course;
  final int semester;
  final double dailyGoalHours;
  final double weeklyGoalHours;
  final String preferredStudyTime;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.university,
    required this.course,
    required this.semester,
    required this.dailyGoalHours,
    required this.weeklyGoalHours,
    required this.preferredStudyTime,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? university,
    String? course,
    int? semester,
    double? dailyGoalHours,
    double? weeklyGoalHours,
    String? preferredStudyTime,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      university: university ?? this.university,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'university': university,
      'course': course,
      'semester': semester,
      'dailyGoalHours': dailyGoalHours,
      'weeklyGoalHours': weeklyGoalHours,
      'preferredStudyTime': preferredStudyTime,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseUpdatedDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      // Handle Firestore Timestamp if passed natively
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return UserProfile(
      uid: docId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      university: map['university'] as String? ?? '',
      course: map['course'] as String? ?? '',
      semester: map['semester'] as int? ?? 1,
      dailyGoalHours: (map['dailyGoalHours'] as num?)?.toDouble() ?? 0.0,
      weeklyGoalHours: (map['weeklyGoalHours'] as num?)?.toDouble() ?? 0.0,
      preferredStudyTime: map['preferredStudyTime'] as String? ?? 'Morning',
      updatedAt: parseUpdatedDate(map['updatedAt']),
    );
  }
}
