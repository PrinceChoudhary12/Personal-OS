// lib/features/goals/data/repositories/firestore_goal_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';

class FirestoreGoalRepository implements GoalRepository {
  final FirebaseFirestore _firestore;

  FirestoreGoalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('goals');

  @override
  Stream<List<GoalModel>> streamGoals(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<GoalModel> getGoalById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Goal not found.');
      }
      return GoalModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createGoal(GoalModel goal) async {
    try {
      await _collection.add(goal.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    try {
      await _collection.doc(goal.id).set(
            goal.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }
}
