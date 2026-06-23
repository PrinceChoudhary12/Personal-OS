// test/features/habits/habits_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/habits/domain/models/habit_model.dart';

void main() {
  group('HabitModel Serialization & Copy Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final model = HabitModel(
        id: 'hab_1',
        userId: 'user_456',
        title: 'Drink Water',
        description: 'Drink 3L of water daily',
        frequency: 'Daily',
        completedDates: const ['2026-06-18', '2026-06-17'],
        color: 0xFF6366F1,
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['title'], 'Drink Water');
      expect(map['userId'], 'user_456');
      expect(map['frequency'], 'Daily');
      expect(map['completedDates'], ['2026-06-18', '2026-06-17']);
      expect(map['color'], 0xFF6366F1);
      expect(map['createdAt'], now.toIso8601String());

      final deserialized = HabitModel.fromMap(map, 'hab_1');
      expect(deserialized.id, 'hab_1');
      expect(deserialized.userId, 'user_456');
      expect(deserialized.title, 'Drink Water');
      expect(deserialized.completedDates, ['2026-06-18', '2026-06-17']);
      expect(deserialized.color, 0xFF6366F1);
    });

    test('fromMap handles null/missing fields gracefully', () {
      final deserialized = HabitModel.fromMap({}, 'hab_null');
      expect(deserialized.id, 'hab_null');
      expect(deserialized.userId, '');
      expect(deserialized.title, '');
      expect(deserialized.frequency, 'Daily');
      expect(deserialized.completedDates, isEmpty);
      expect(deserialized.color, 0xFF4F46E5);
    });

    test('copyWith works correctly', () {
      final original = HabitModel(
        id: 'hab_orig',
        userId: 'user_1',
        title: 'Exercise',
        description: 'Go to gym',
        frequency: 'Daily',
        completedDates: const [],
        color: 0xFF10B981,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cloned = original.copyWith(title: 'Read Books', completedDates: ['2026-06-18']);
      expect(cloned.id, 'hab_orig');
      expect(cloned.title, 'Read Books');
      expect(cloned.completedDates, ['2026-06-18']);
      expect(cloned.color, 0xFF10B981);
    });
  });

  group('Habit Streak Calculations', () {
    test('currentStreak is 0 when no dates are completed', () {
      final model = HabitModel(
        id: '1',
        userId: 'u',
        title: 'T',
        description: 'D',
        frequency: 'Daily',
        completedDates: const [],
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(model.currentStreak, 0);
    });

    test('currentStreak accounts for consecutive days including today/yesterday', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final dayBefore = now.subtract(const Duration(days: 2));
      final dayBeforeStr = '${dayBefore.year}-${dayBefore.month.toString().padLeft(2, '0')}-${dayBefore.day.toString().padLeft(2, '0')}';

      // Test active streak completed today
      final modelActiveToday = HabitModel(
        id: '1',
        userId: 'u',
        title: 'T',
        description: 'D',
        frequency: 'Daily',
        completedDates: [todayStr, yesterdayStr, dayBeforeStr],
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(modelActiveToday.currentStreak, 3);

      // Test active streak completed yesterday but not today
      final modelActiveYesterday = HabitModel(
        id: '1',
        userId: 'u',
        title: 'T',
        description: 'D',
        frequency: 'Daily',
        completedDates: [yesterdayStr, dayBeforeStr],
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(modelActiveYesterday.currentStreak, 2);

      // Test broken streak (completed dayBefore but not today or yesterday)
      final modelBroken = HabitModel(
        id: '1',
        userId: 'u',
        title: 'T',
        description: 'D',
        frequency: 'Daily',
        completedDates: [dayBeforeStr],
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(modelBroken.currentStreak, 0);
    });

    test('longestStreak returns correct max sequence of days', () {
      final now = DateTime.now();
      String dtStr(int offsetDays) {
        final d = now.subtract(Duration(days: offsetDays));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      // Completed offsets: 0, 1, 2 (streak of 3) and 5, 6, 7, 8 (streak of 4)
      final model = HabitModel(
        id: '1',
        userId: 'u',
        title: 'T',
        description: 'D',
        frequency: 'Daily',
        completedDates: [
          dtStr(0), dtStr(1), dtStr(2), // 3 days
          dtStr(5), dtStr(6), dtStr(7), dtStr(8), // 4 days
        ],
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(model.longestStreak, 4);
    });
  });
}
