// test/features/scheduler/scheduler_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/scheduler/domain/models/scheduler_model.dart';

void main() {
  group('SchedulerModel Serialization Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 1));
      final endTime = now.add(const Duration(hours: 2));

      final model = SchedulerModel(
        id: 'sch_1',
        userId: 'user_999',
        title: 'Complete Personal OS Scheduler',
        startTime: startTime,
        endTime: endTime,
        category: 'Coding',
        priority: 'High',
        completed: false,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'sch_1');
      expect(map['userId'], 'user_999');
      expect(map['title'], 'Complete Personal OS Scheduler');
      expect(map['startTime'], startTime.toIso8601String());
      expect(map['endTime'], endTime.toIso8601String());
      expect(map['category'], 'Coding');
      expect(map['priority'], 'High');
      expect(map['completed'], false);
      expect(map['createdAt'], now.toIso8601String());

      final deserialized = SchedulerModel.fromMap(map, 'sch_1');
      expect(deserialized.id, 'sch_1');
      expect(deserialized.userId, 'user_999');
      expect(deserialized.title, 'Complete Personal OS Scheduler');
      expect(deserialized.startTime.toIso8601String(), startTime.toIso8601String());
      expect(deserialized.endTime.toIso8601String(), endTime.toIso8601String());
      expect(deserialized.category, 'Coding');
      expect(deserialized.priority, 'High');
      expect(deserialized.completed, false);
    });

    test('fromMap fallback works with null / empty fields', () {
      final deserialized = SchedulerModel.fromMap({}, 'sch_test');
      expect(deserialized.id, 'sch_test');
      expect(deserialized.userId, '');
      expect(deserialized.title, '');
      expect(deserialized.category, 'General');
      expect(deserialized.priority, 'Medium');
      expect(deserialized.completed, false);
      expect(deserialized.startTime, isA<DateTime>());
      expect(deserialized.endTime, isA<DateTime>());
      expect(deserialized.createdAt, isA<DateTime>());
    });

    test('copyWith properly clones and overrides fields', () {
      final original = SchedulerModel(
        id: 'sch_2',
        userId: 'user_111',
        title: 'Gym Workout',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        category: 'Workout',
        priority: 'Medium',
        completed: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(completed: true, priority: 'Low');
      expect(updated.id, 'sch_2');
      expect(updated.completed, true);
      expect(updated.priority, 'Low');
      expect(updated.title, 'Gym Workout');
    });
  });

  group('Scheduler Logic & Chronological Sorting', () {
    test('schedules list sorting sorts chronologically by startTime', () {
      final now = DateTime.now();

      final first = SchedulerModel(
        id: '1',
        userId: 'user_1',
        title: 'Morning Standup',
        startTime: now.add(const Duration(hours: 9)),
        endTime: now.add(const Duration(hours: 9, minutes: 30)),
        category: 'Meeting',
        priority: 'High',
        completed: false,
        createdAt: now,
      );

      final second = SchedulerModel(
        id: '2',
        userId: 'user_1',
        title: 'Coding Sprint',
        startTime: now.add(const Duration(hours: 10)),
        endTime: now.add(const Duration(hours: 12)),
        category: 'Coding',
        priority: 'High',
        completed: false,
        createdAt: now,
      );

      final third = SchedulerModel(
        id: '3',
        userId: 'user_1',
        title: 'Lunch Break',
        startTime: now.add(const Duration(hours: 12, minutes: 30)),
        endTime: now.add(const Duration(hours: 13, minutes: 30)),
        category: 'Rest/Break',
        priority: 'Low',
        completed: true,
        createdAt: now,
      );

      // Unordered list
      final list = [third, first, second];

      // Sorting (matching firestore_scheduler_repository logic)
      list.sort((a, b) => a.startTime.compareTo(b.startTime));

      expect(list[0].id, '1');
      expect(list[1].id, '2');
      expect(list[2].id, '3');
    });
  });
}
