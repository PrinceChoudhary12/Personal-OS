// lib/features/student_hub/presentation/providers/student_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/placement_model.dart';

final subjectsStreamProvider = StreamProvider<List<SubjectModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(studentRepositoryProvider);
  return repo.streamSubjects(user.uid);
});

final attendanceStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(studentRepositoryProvider);
  return repo.streamAttendance(user.uid);
});

final assignmentsStreamProvider = StreamProvider<List<AssignmentModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(studentRepositoryProvider);
  return repo.streamAssignments(user.uid);
});

final placementsStreamProvider = StreamProvider<List<PlacementModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(studentRepositoryProvider);
  return repo.streamPlacements(user.uid);
});

class StudentHubController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  StudentHubController(this._ref) : super(const AsyncValue.data(null));

  // --- Subjects CRUD ---
  Future<void> addSubject(SubjectModel subject) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.createSubject(subject);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editSubject(SubjectModel subject) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.updateSubject(subject);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteSubject(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.deleteSubject(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Attendance Actions ---
  Future<void> logAttendance(AttendanceModel attendance) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.logAttendance(attendance);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.updateAttendance(attendance);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteAttendance(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.deleteAttendance(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Assignments CRUD ---
  Future<void> addAssignment(AssignmentModel assignment) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.createAssignment(assignment);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editAssignment(AssignmentModel assignment) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.updateAssignment(assignment);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteAssignment(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.deleteAssignment(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Placement Actions ---
  Future<void> addPlacement(PlacementModel placement) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.createPlacement(placement);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editPlacement(PlacementModel placement) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.updatePlacement(placement);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deletePlacement(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentRepositoryProvider);
      await repo.deletePlacement(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final studentHubControllerProvider =
    StateNotifierProvider<StudentHubController, AsyncValue<void>>((ref) {
  return StudentHubController(ref);
});
