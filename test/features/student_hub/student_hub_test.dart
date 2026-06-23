// test/features/student_hub/student_hub_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/student_hub/domain/models/subject_model.dart';
import 'package:personal_os/features/student_hub/domain/models/attendance_model.dart';
import 'package:personal_os/features/student_hub/domain/models/assignment_model.dart';
import 'package:personal_os/features/student_hub/domain/models/placement_model.dart';

void main() {
  group('SubjectModel Serialization & GPA Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final model = SubjectModel(
        id: 'sub_1',
        userId: 'user_123',
        name: 'Mathematics',
        code: 'MATH101',
        credits: 4.0,
        grade: 'A',
        gradePoint: 9.0,
        semester: 2,
        isCompleted: true,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['name'], 'Mathematics');
      expect(map['code'], 'MATH101');
      expect(map['credits'], 4.0);
      expect(map['grade'], 'A');
      expect(map['gradePoint'], 9.0);
      expect(map['semester'], 2);
      expect(map['isCompleted'], true);

      final deserialized = SubjectModel.fromMap(map, 'sub_1');
      expect(deserialized.id, 'sub_1');
      expect(deserialized.userId, 'user_123');
      expect(deserialized.name, 'Mathematics');
      expect(deserialized.credits, 4.0);
      expect(deserialized.gradePoint, 9.0);
    });

    test('GPAs are calculated correctly from subjects list', () {
      final now = DateTime.now();
      final subjects = [
        SubjectModel(
          id: '1',
          userId: 'u',
          name: 'S1',
          code: 'C1',
          credits: 4.0,
          grade: 'A',
          gradePoint: 9.0,
          semester: 1,
          isCompleted: true,
          createdAt: now,
        ),
        SubjectModel(
          id: '2',
          userId: 'u',
          name: 'S2',
          code: 'C2',
          credits: 3.0,
          grade: 'B',
          gradePoint: 8.0,
          semester: 1,
          isCompleted: true,
          createdAt: now,
        ),
        SubjectModel(
          id: '3',
          userId: 'u',
          name: 'S3',
          code: 'C3',
          credits: 3.0,
          grade: 'C',
          gradePoint: 7.0,
          semester: 1,
          isCompleted: false, // Incompleted, shouldn't be counted in CGPA
          createdAt: now,
        ),
      ];

      // CGPA = (4 * 9.0 + 3 * 8.0) / (4.0 + 3.0) = (36 + 24) / 7 = 60 / 7 = 8.57
      double totalCredits = 0.0;
      double totalPoints = 0.0;
      for (final s in subjects) {
        if (s.isCompleted && s.gradePoint != null) {
          totalCredits += s.credits;
          totalPoints += (s.credits * s.gradePoint!);
        }
      }
      final cgpa = totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;
      expect(cgpa, closeTo(8.57, 0.01));
    });
  });

  group('AttendanceModel Serialization & Ratio Tests', () {
    test('toMap and fromMap matches', () {
      final now = DateTime.now();
      final log = AttendanceModel(
        id: 'att_1',
        userId: 'user_1',
        subjectId: 'sub_1',
        date: now,
        status: 'present',
        notes: 'Felt great',
      );

      final map = log.toMap();
      expect(map['status'], 'present');
      expect(map['notes'], 'Felt great');

      final parsed = AttendanceModel.fromMap(map, 'att_1');
      expect(parsed.id, 'att_1');
      expect(parsed.status, 'present');
      expect(parsed.notes, 'Felt great');
    });

    test('calculates attendance percentage correctly', () {
      final logs = [
        AttendanceModel(id: '1', userId: 'u', subjectId: 's', date: DateTime.now(), status: 'present'),
        AttendanceModel(id: '2', userId: 'u', subjectId: 's', date: DateTime.now(), status: 'present'),
        AttendanceModel(id: '3', userId: 'u', subjectId: 's', date: DateTime.now(), status: 'absent'),
        AttendanceModel(id: '4', userId: 'u', subjectId: 's', date: DateTime.now(), status: 'excused'), // excused shouldn't affect ratio
      ];

      final presents = logs.where((l) => l.status == 'present').length;
      final absents = logs.where((l) => l.status == 'absent').length;
      final total = presents + absents;
      final rate = total > 0 ? (presents / total) * 100.0 : 100.0;

      expect(rate, closeTo(66.67, 0.01));
    });
  });

  group('AssignmentModel & PlacementModel Serialization', () {
    test('AssignmentModel serialization matches', () {
      final now = DateTime.now();
      final assignment = AssignmentModel(
        id: 'asg_1',
        userId: 'u',
        subjectId: 's',
        title: 'Project 1',
        description: 'Complete compiler project',
        dueDate: now,
        status: 'Pending',
        createdAt: now,
      );

      final map = assignment.toMap();
      final parsed = AssignmentModel.fromMap(map, 'asg_1');
      expect(parsed.title, 'Project 1');
      expect(parsed.status, 'Pending');
    });

    test('PlacementModel serialization matches', () {
      final now = DateTime.now();
      final placement = PlacementModel(
        id: 'plc_1',
        userId: 'u',
        company: 'Google',
        role: 'SWE Intern',
        status: 'Interviewing',
        salary: '100k',
        location: 'Mountain View',
        notes: 'Review algorithms',
        createdAt: now,
        updatedAt: now,
      );

      final map = placement.toMap();
      final parsed = PlacementModel.fromMap(map, 'plc_1');
      expect(parsed.company, 'Google');
      expect(parsed.status, 'Interviewing');
      expect(parsed.location, 'Mountain View');
    });
  });
}
