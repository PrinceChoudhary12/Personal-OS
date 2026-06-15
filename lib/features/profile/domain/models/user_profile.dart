// lib/features/profile/domain/models/user_profile.dart

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String university;
  final String course;
  final int semester;
  final List<String> skills;
  final String careerGoal;
  final String bio;
  final double dailyGoalHours;
  final double weeklyGoalHours;
  final String preferredStudyTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.university,
    required this.course,
    required this.semester,
    required this.skills,
    required this.careerGoal,
    required this.bio,
    required this.dailyGoalHours,
    required this.weeklyGoalHours,
    required this.preferredStudyTime,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? university,
    String? course,
    int? semester,
    List<String>? skills,
    String? careerGoal,
    String? bio,
    double? dailyGoalHours,
    double? weeklyGoalHours,
    String? preferredStudyTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      university: university ?? this.university,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      skills: skills ?? this.skills,
      careerGoal: careerGoal ?? this.careerGoal,
      bio: bio ?? this.bio,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'university': university,
      'course': course,
      'semester': semester,
      'skills': skills,
      'careerGoal': careerGoal,
      'bio': bio,
      'dailyGoalHours': dailyGoalHours,
      'weeklyGoalHours': weeklyGoalHours,
      'preferredStudyTime': preferredStudyTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
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

    final rawSkills = map['skills'];
    final List<String> parsedSkills = rawSkills is List
        ? rawSkills.map((e) => e.toString()).toList()
        : const [];

    return UserProfile(
      uid: docId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      university: map['university'] as String? ?? '',
      course: map['course'] as String? ?? '',
      semester: map['semester'] as int? ?? 1,
      skills: parsedSkills,
      careerGoal: map['careerGoal'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      dailyGoalHours: (map['dailyGoalHours'] as num?)?.toDouble() ?? 0.0,
      weeklyGoalHours: (map['weeklyGoalHours'] as num?)?.toDouble() ?? 0.0,
      preferredStudyTime: map['preferredStudyTime'] as String? ?? 'Morning',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
