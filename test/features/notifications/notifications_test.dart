// test/features/notifications/notifications_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/notifications/domain/models/reminder_model.dart';

void main() {
  group('ReminderModel Serialization & Copy Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final reminderTime = now.add(const Duration(hours: 4));

      final model = ReminderModel(
        id: 'rem_1',
        userId: 'user_123',
        title: 'Review Clean Architecture goals',
        description: 'Complete milestones before Friday',
        reminderTime: reminderTime,
        type: 'Goal',
        completed: false,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'rem_1');
      expect(map['userId'], 'user_123');
      expect(map['title'], 'Review Clean Architecture goals');
      expect(map['description'], 'Complete milestones before Friday');
      expect(map['reminderTime'], reminderTime.toIso8601String());
      expect(map['type'], 'Goal');
      expect(map['completed'], false);
      expect(map['createdAt'], now.toIso8601String());

      final deserialized = ReminderModel.fromMap(map, 'rem_1');
      expect(deserialized.id, 'rem_1');
      expect(deserialized.userId, 'user_123');
      expect(deserialized.title, 'Review Clean Architecture goals');
      expect(deserialized.reminderTime.toIso8601String(), reminderTime.toIso8601String());
      expect(deserialized.type, 'Goal');
      expect(deserialized.completed, false);
    });

    test('fromMap handles missing/null values gracefully', () {
      final deserialized = ReminderModel.fromMap({}, 'rem_null');
      expect(deserialized.id, 'rem_null');
      expect(deserialized.userId, '');
      expect(deserialized.title, '');
      expect(deserialized.description, '');
      expect(deserialized.type, 'General');
      expect(deserialized.completed, false);
      expect(deserialized.reminderTime, isA<DateTime>());
      expect(deserialized.createdAt, isA<DateTime>());
    });

    test('copyWith works correctly', () {
      final original = ReminderModel(
        id: 'rem_original',
        userId: 'user_9',
        title: 'Initial Title',
        description: 'Initial Description',
        reminderTime: DateTime.now(),
        type: 'Focus',
        completed: false,
        createdAt: DateTime.now(),
      );

      final cloned = original.copyWith(completed: true, title: 'Updated Title');
      expect(cloned.id, 'rem_original');
      expect(cloned.completed, true);
      expect(cloned.title, 'Updated Title');
      expect(cloned.description, 'Initial Description');
    });
  });

  group('Smart Logic Calculations', () {
    test('Goal deadline < 3 days calculation math logic', () {
      final now = DateTime.now();

      // Goal created 5 days ago (milestone deadline approaching: 7 - 5 = 2 days left)
      final goalCreatedAt = now.subtract(const Duration(days: 5));
      final deadline = goalCreatedAt.add(const Duration(days: 7));
      final daysRemaining = deadline.difference(now).inDays;

      expect(daysRemaining, 2);
      final isApproaching = daysRemaining >= 0 && daysRemaining < 3;
      expect(isApproaching, true);
    });

    test('Goal deadline >= 3 days calculation math logic', () {
      final now = DateTime.now();

      // Goal created 1 day ago (milestone deadline: 7 - 1 = 6 days left)
      final goalCreatedAt = now.subtract(const Duration(days: 1));
      final deadline = goalCreatedAt.add(const Duration(days: 7));
      final daysRemaining = deadline.difference(now).inDays;

      expect(daysRemaining, 6);
      final isApproaching = daysRemaining >= 0 && daysRemaining < 3;
      expect(isApproaching, false);
    });
  });
}
