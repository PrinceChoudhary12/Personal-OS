// lib/features/gamification/domain/models/xp_model.dart

class XpModel {
  final String userId;
  final int currentXp; // XP earned inside the current level
  final int totalXp;   // Cumulative overall XP
  final int level;     // Current level
  final int nextLevelXp; // Cumulative total XP required to level up to the next level
  final DateTime updatedAt;

  const XpModel({
    required this.userId,
    required this.currentXp,
    required this.totalXp,
    required this.level,
    required this.nextLevelXp,
    required this.updatedAt,
  });

  XpModel copyWith({
    String? userId,
    int? currentXp,
    int? totalXp,
    int? level,
    int? nextLevelXp,
    DateTime? updatedAt,
  }) {
    return XpModel(
      userId: userId ?? this.userId,
      currentXp: currentXp ?? this.currentXp,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentXp': currentXp,
      'totalXp': totalXp,
      'level': level,
      'nextLevelXp': nextLevelXp,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory XpModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return XpModel(
      userId: docId,
      currentXp: map['currentXp'] as int? ?? 0,
      totalXp: map['totalXp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      nextLevelXp: map['nextLevelXp'] as int? ?? 100,
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

class LevelCalculator {
  /// Returns the cumulative total XP needed to reach a specific level.
  /// Level 1 = 0 XP
  /// Level 2 = 100 XP
  /// Level 3 = 250 XP
  /// Level 4 = 500 XP
  /// Increment formula: Diff(L) = Diff(L-1) + 50 * (L-1)
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    int xp = 0;
    int increment = 100;
    for (int l = 1; l < level; l++) {
      xp += increment;
      increment += 50 * l;
    }
    return xp;
  }

  /// Calculates the level for a given total cumulative XP.
  static int calculateLevel(int totalXp) {
    if (totalXp < 0) totalXp = 0;
    int level = 1;
    while (xpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }
}
