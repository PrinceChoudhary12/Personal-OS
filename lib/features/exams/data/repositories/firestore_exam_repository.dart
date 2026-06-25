// lib/features/exams/data/repositories/firestore_exam_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/exam_model.dart';
import '../../domain/models/revision_plan_model.dart';
import '../../domain/repositories/exam_repository.dart';

class FirestoreExamRepository implements ExamRepository {
  final FirebaseFirestore _firestore;

  FirestoreExamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _examsCol =>
      _firestore.collection('exams');

  CollectionReference<Map<String, dynamic>> get _revisionPlansCol =>
      _firestore.collection('revision_plans');

  @override
  Stream<List<ExamModel>> streamExams(String userId) {
    return _examsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by examDate ascending
      list.sort((a, b) => a.examDate.compareTo(b.examDate));
      return list;
    });
  }

  @override
  Future<List<ExamModel>> getExams(String userId) async {
    try {
      final snapshot = await _examsCol.where('userId', isEqualTo: userId).get();
      final list = snapshot.docs
          .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.examDate.compareTo(b.examDate));
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<ExamModel?> getExamById(String id) async {
    try {
      final doc = await _examsCol.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return ExamModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createExam(ExamModel exam) async {
    try {
      final docRef = exam.id.isEmpty ? _examsCol.doc() : _examsCol.doc(exam.id);
      final toSave = exam.id.isEmpty ? exam.copyWith(id: docRef.id) : exam;
      await docRef.set(toSave.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateExam(ExamModel exam) async {
    try {
      await _examsCol.doc(exam.id).set(exam.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteExam(String id) async {
    try {
      // Delete exam
      await _examsCol.doc(id).delete();
      
      // Delete all related revision plans
      final plans = await _revisionPlansCol.where('examId', isEqualTo: id).get();
      final batch = _firestore.batch();
      for (final doc in plans.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<List<RevisionPlanModel>> streamRevisionPlans(String examId) {
    return _revisionPlansCol
        .where('examId', isEqualTo: examId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RevisionPlanModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by createdAt ascending
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  @override
  Future<List<RevisionPlanModel>> getRevisionPlans(String examId) async {
    try {
      final snapshot = await _revisionPlansCol.where('examId', isEqualTo: examId).get();
      final list = snapshot.docs
          .map((doc) => RevisionPlanModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createRevisionPlan(RevisionPlanModel plan) async {
    try {
      final docRef = plan.id.isEmpty ? _revisionPlansCol.doc() : _revisionPlansCol.doc(plan.id);
      final toSave = plan.id.isEmpty ? plan.copyWith(id: docRef.id) : plan;
      await docRef.set(toSave.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateRevisionPlan(RevisionPlanModel plan) async {
    try {
      await _revisionPlansCol.doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteRevisionPlan(String id) async {
    try {
      await _revisionPlansCol.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }
}
