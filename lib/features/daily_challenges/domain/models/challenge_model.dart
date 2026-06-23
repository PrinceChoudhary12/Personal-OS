// lib/features/daily_challenges/domain/models/challenge_model.dart

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.completed,
    required this.createdAt,
    this.completedAt,
  });

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return ChallengeModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      xpReward: map['xpReward'] as int? ?? 15,
      completed: map['completed'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      completedAt: parseNullableDate(map['completedAt']),
    );
  }
}
