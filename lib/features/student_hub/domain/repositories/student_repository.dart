// lib/features/student_hub/domain/repositories/student_repository.dart

import '../models/subject_model.dart';
import '../models/attendance_model.dart';
import '../models/assignment_model.dart';
import '../models/placement_model.dart';

abstract class StudentRepository {
  // Subjects
  Stream<List<SubjectModel>> streamSubjects(String userId);
  Future<void> createSubject(SubjectModel subject);
  Future<void> updateSubject(SubjectModel subject);
  Future<void> deleteSubject(String id);

  // Attendance
  Stream<List<AttendanceModel>> streamAttendance(String userId);
  Future<void> logAttendance(AttendanceModel attendance);
  Future<void> updateAttendance(AttendanceModel attendance);
  Future<void> deleteAttendance(String id);

  // Assignments
  Stream<List<AssignmentModel>> streamAssignments(String userId);
  Future<void> createAssignment(AssignmentModel assignment);
  Future<void> updateAssignment(AssignmentModel assignment);
  Future<void> deleteAssignment(String id);

  // Placements
  Stream<List<PlacementModel>> streamPlacements(String userId);
  Future<void> createPlacement(PlacementModel placement);
  Future<void> updatePlacement(PlacementModel placement);
  Future<void> deletePlacement(String id);
}
