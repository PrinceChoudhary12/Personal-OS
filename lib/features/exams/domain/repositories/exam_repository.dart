// lib/features/exams/domain/repositories/exam_repository.dart

import '../models/exam_model.dart';
import '../models/revision_plan_model.dart';

abstract class ExamRepository {
  Stream<List<ExamModel>> streamExams(String userId);
  Future<List<ExamModel>> getExams(String userId);
  Future<ExamModel?> getExamById(String id);
  Future<void> createExam(ExamModel exam);
  Future<void> updateExam(ExamModel exam);
  Future<void> deleteExam(String id);

  Stream<List<RevisionPlanModel>> streamRevisionPlans(String examId);
  Future<List<RevisionPlanModel>> getRevisionPlans(String examId);
  Future<void> createRevisionPlan(RevisionPlanModel plan);
  Future<void> updateRevisionPlan(RevisionPlanModel plan);
  Future<void> deleteRevisionPlan(String id);
}
