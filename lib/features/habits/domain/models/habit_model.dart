// lib/features/habits/domain/models/habit_model.dart

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String frequency; // 'Daily', 'Weekly'
  final List<String> completedDates; // Format: yyyy-MM-dd
  final int color; // UI indicator color representation
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.frequency,
    required this.completedDates,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate current streak of consecutive days completed
  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final dates = completedDates
        .map((d) => DateTime.tryParse(d))
        .where((d) => d != null)
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;
    dates.sort((a, b) => b.compareTo(a)); // Sort descending

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // A streak is only currently active if completed today or yesterday
    final firstCompleted = dates.first;
    if (firstCompleted != today && firstCompleted != yesterday) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = firstCompleted;

    for (final d in dates) {
      if (d == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Calculate the longest streak sequence of consecutive days completed
  int get longestStreak {
    if (completedDates.isEmpty) return 0;

    final dates = completedDates
        .map((d) => DateTime.tryParse(d))
        .where((d) => d != null)
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;
    dates.sort((a, b) => a.compareTo(b)); // Sort ascending

    int maxStreak = 0;
    int currentRun = 0;
    DateTime? prev;

    for (final d in dates) {
      if (prev == null) {
        currentRun = 1;
      } else {
        final diff = d.difference(prev).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          if (currentRun > maxStreak) {
            maxStreak = currentRun;
          }
          currentRun = 1;
        }
      }
      prev = d;
    }

    if (currentRun > maxStreak) {
      maxStreak = currentRun;
    }
    return maxStreak;
  }

  // Helper check if this habit is completed today
  bool get isCompletedToday {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return completedDates.contains(todayStr);
  }

  HabitModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? frequency,
    List<String>? completedDates,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      completedDates: completedDates ?? this.completedDates,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'frequency': frequency,
      'completedDates': completedDates,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map, String docId) {
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

    final rawCompleted = map['completedDates'];
    List<String> parsedCompletions = [];
    if (rawCompleted is List) {
      parsedCompletions = rawCompleted.map((e) => e.toString()).toList();
    }

    return HabitModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'Daily',
      completedDates: parsedCompletions,
      color: map['color'] as int? ?? 0xFF4F46E5,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
