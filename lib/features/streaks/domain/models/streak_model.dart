// lib/features/streaks/domain/models/streak_model.dart

class StreakModel {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final List<String> history;

  const StreakModel({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.history,
  });

  int get missedDaysInLast30Days {
    final today = DateTime.now();
    int missed = 0;
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!history.contains(dateStr)) {
        missed++;
      }
    }
    return missed;
  }

  StreakModel copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    List<String>? history,
  }) {
    return StreakModel(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'history': history,
    };
  }

  factory StreakModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return StreakModel(
      userId: map['userId'] as String? ?? docId,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastActivityDate: parseDate(map['lastActivityDate']),
      history: List<String>.from(map['history'] ?? const []),
    );
  }
}
