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
}
