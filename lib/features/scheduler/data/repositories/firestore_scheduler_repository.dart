// lib/features/scheduler/data/repositories/firestore_scheduler_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/scheduler_model.dart';
import '../../domain/repositories/scheduler_repository.dart';

class FirestoreSchedulerRepository implements SchedulerRepository {
  final FirebaseFirestore _firestore;

  FirestoreSchedulerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('schedules');

  @override
  Stream<List<SchedulerModel>> streamSchedules(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        // Only return individual documents that have valid fields matching our SchedulerModel schema.
        // If a document represents a legacy daily schedule map (which has a 'scheduledTasks' field),
        // we filter it out to prevent crashes in the individual tasks view.
        return SchedulerModel.fromMap(doc.data(), doc.id);
      }).where((model) => model.title.isNotEmpty).toList();

      // Sort chronologically by startTime
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  @override
  Future<void> createSchedule(SchedulerModel schedule) async {
    final docRef = schedule.id.isEmpty
        ? _collection.doc()
        : _collection.doc(schedule.id);

    final toSave = schedule.id.isEmpty
        ? schedule.copyWith(id: docRef.id)
        : schedule;

    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateSchedule(SchedulerModel schedule) async {
    await _collection.doc(schedule.id).set(schedule.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _collection.doc(id).delete();
  }
}
