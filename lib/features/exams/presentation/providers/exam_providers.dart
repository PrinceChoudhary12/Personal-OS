// lib/features/exams/presentation/providers/exam_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/exam_model.dart';
import '../../domain/models/revision_plan_model.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

// --- Stream of Exams for the current user ---
final examsStreamProvider = StreamProvider<List<ExamModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(examRepositoryProvider);
  return repo.streamExams(user.uid);
});

// --- Stream of Revision Plans (Topics) for a specific exam ---
final revisionPlansStreamProvider = StreamProvider.family<List<RevisionPlanModel>, String>((ref, examId) {
  final repo = ref.watch(examRepositoryProvider);
  return repo.streamRevisionPlans(examId);
});

// --- Exam Controller Provider for CRUD Actions ---
class ExamController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ExamController(this._ref) : super(const AsyncValue.data(null));

  ExamRepository get _repo => _ref.read(examRepositoryProvider);

  Future<void> addExam(ExamModel exam) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createExam(exam);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Exam Scheduled 📝',
        'New exam scheduled for ${exam.subject} on ${exam.examDate.day}/${exam.examDate.month}. Priority: ${exam.priority}.',
        'Academic',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editExam(ExamModel exam) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateExam(exam);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Exam Updated 📝',
        'Syllabus or target details updated for ${exam.subject}.',
        'Academic',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteExam(String id, String subjectName) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteExam(id);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Exam Removed 🗑️',
        'Exam tracker for $subjectName was deleted.',
        'Academic',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Revision Plan Actions ---
  Future<void> addRevisionPlan(RevisionPlanModel plan) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createRevisionPlan(plan);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleRevisionPlanCompletion(RevisionPlanModel plan) async {
    state = const AsyncValue.loading();
    try {
      final updated = plan.copyWith(
        isCompleted: !plan.isCompleted,
        updatedAt: DateTime.now(),
      );
      await _repo.updateRevisionPlan(updated);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteRevisionPlan(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteRevisionPlan(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final examControllerProvider =
    StateNotifierProvider<ExamController, AsyncValue<void>>((ref) {
  return ExamController(ref);
});
