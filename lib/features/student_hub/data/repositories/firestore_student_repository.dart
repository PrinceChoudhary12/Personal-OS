// lib/features/student_hub/data/repositories/firestore_student_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/placement_model.dart';
import '../../domain/repositories/student_repository.dart';

class FirestoreStudentRepository implements StudentRepository {
  final FirebaseFirestore _firestore;

  FirestoreStudentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subjectsCol =>
      _firestore.collection('subjects');

  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _firestore.collection('attendance');

  CollectionReference<Map<String, dynamic>> get _assignmentsCol =>
      _firestore.collection('assignments');

  CollectionReference<Map<String, dynamic>> get _placementsCol =>
      _firestore.collection('placement_progress');

  // Subjects
  @override
  Stream<List<SubjectModel>> streamSubjects(String userId) {
    return _subjectsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> createSubject(SubjectModel subject) async {
    await _subjectsCol.add(subject.toMap());
  }

  @override
  Future<void> updateSubject(SubjectModel subject) async {
    await _subjectsCol.doc(subject.id).update(subject.toMap());
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _subjectsCol.doc(id).delete();
  }

  // Attendance
  @override
  Stream<List<AttendanceModel>> streamAttendance(String userId) {
    return _attendanceCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> logAttendance(AttendanceModel attendance) async {
    await _attendanceCol.add(attendance.toMap());
  }

  @override
  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _attendanceCol.doc(attendance.id).update(attendance.toMap());
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await _attendanceCol.doc(id).delete();
  }

  // Assignments
  @override
  Stream<List<AssignmentModel>> streamAssignments(String userId) {
    return _assignmentsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> createAssignment(AssignmentModel assignment) async {
    await _assignmentsCol.add(assignment.toMap());
  }

  @override
  Future<void> updateAssignment(AssignmentModel assignment) async {
    await _assignmentsCol.doc(assignment.id).update(assignment.toMap());
  }

  @override
  Future<void> deleteAssignment(String id) async {
    await _assignmentsCol.doc(id).delete();
  }

  // Placements
  @override
  Stream<List<PlacementModel>> streamPlacements(String userId) {
    return _placementsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlacementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> createPlacement(PlacementModel placement) async {
    await _placementsCol.add(placement.toMap());
  }

  @override
  Future<void> updatePlacement(PlacementModel placement) async {
    await _placementsCol.doc(placement.id).update(placement.toMap());
  }

  @override
  Future<void> deletePlacement(String id) async {
    await _placementsCol.doc(id).delete();
  }
}
