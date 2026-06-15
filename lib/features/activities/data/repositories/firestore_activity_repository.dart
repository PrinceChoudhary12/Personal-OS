// lib/features/activities/data/repositories/firestore_activity_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/repositories/activity_repository.dart';

class FirestoreActivityRepository implements ActivityRepository {
  final FirebaseFirestore _firestore;

  FirestoreActivityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activities');

  @override
  Stream<List<ActivityModel>> streamActivities(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();
      // Order programmatically to avoid requirement of manual Firestore index during testing/eval
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }

  @override
  Future<ActivityModel> getActivityById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Activity not found.');
      }
      return ActivityModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createActivity(ActivityModel activity) async {
    try {
      await _collection.add(activity.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateActivity(ActivityModel activity) async {
    try {
      await _collection.doc(activity.id).set(
            activity.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteActivity(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }
}
