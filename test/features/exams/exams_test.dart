// test/features/exams/exams_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/exams/domain/models/exam_model.dart';
import 'package:personal_os/features/exams/domain/models/revision_plan_model.dart';

void main() {
  group('ExamModel Serialization & Target Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final exam = ExamModel(
        id: 'exam_1',
        userId: 'user_1',
        subject: 'Algorithms and Data Structures',
        examDate: now.add(const Duration(days: 5)),
        priority: 'High',
        syllabus: 'Chapters 1 to 10',
        dailyStudyGoalMinutes: 90,
        weeklyStudyGoalMinutes: 450,
        createdAt: now,
      );

      final map = exam.toMap();
      expect(map['subject'], 'Algorithms and Data Structures');
      expect(map['priority'], 'High');
      expect(map['dailyStudyGoalMinutes'], 90);
      expect(map['weeklyStudyGoalMinutes'], 450);

      final fromMap = ExamModel.fromMap(map, 'exam_1');
      expect(fromMap.id, 'exam_1');
      expect(fromMap.subject, 'Algorithms and Data Structures');
      expect(fromMap.priority, 'High');
      expect(fromMap.dailyStudyGoalMinutes, 90);
      expect(fromMap.weeklyStudyGoalMinutes, 450);
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final exam = ExamModel(
        id: 'exam_1',
        userId: 'user_1',
        subject: 'Algorithms and Data Structures',
        examDate: now.add(const Duration(days: 5)),
        priority: 'High',
        syllabus: 'Chapters 1 to 10',
        dailyStudyGoalMinutes: 90,
        weeklyStudyGoalMinutes: 450,
        createdAt: now,
      );

      final copy = exam.copyWith(subject: 'Database Systems', priority: 'Medium');
      expect(copy.id, 'exam_1');
      expect(copy.subject, 'Database Systems');
      expect(copy.priority, 'Medium');
      expect(copy.dailyStudyGoalMinutes, 90);
    });

    test('daysRemaining calculation returns accurate count', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 3));
      
      final exam = ExamModel(
        id: 'exam_1',
        userId: 'user_1',
        subject: 'Linear Algebra',
        examDate: targetDate,
        priority: 'Low',
        syllabus: 'All chapters',
        dailyStudyGoalMinutes: 45,
        weeklyStudyGoalMinutes: 200,
        createdAt: now,
      );

      expect(exam.daysRemaining, 3);
    });
  });

  group('RevisionPlanModel Serialization Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final plan = RevisionPlanModel(
        id: 'plan_1',
        examId: 'exam_1',
        userId: 'user_1',
        topicName: 'Sorting Algorithms',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = plan.toMap();
      expect(map['examId'], 'exam_1');
      expect(map['topicName'], 'Sorting Algorithms');
      expect(map['isCompleted'], true);

      final fromMap = RevisionPlanModel.fromMap(map, 'plan_1');
      expect(fromMap.id, 'plan_1');
      expect(fromMap.topicName, 'Sorting Algorithms');
      expect(fromMap.isCompleted, true);
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final plan = RevisionPlanModel(
        id: 'plan_1',
        examId: 'exam_1',
        userId: 'user_1',
        topicName: 'Sorting Algorithms',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final copy = plan.copyWith(isCompleted: true);
      expect(copy.id, 'plan_1');
      expect(copy.topicName, 'Sorting Algorithms');
      expect(copy.isCompleted, true);
    });
  });
}
