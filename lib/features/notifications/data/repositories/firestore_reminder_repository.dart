// lib/features/notifications/data/repositories/firestore_reminder_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/repositories/reminder_repository.dart';

class FirestoreReminderRepository implements ReminderRepository {
  final FirebaseFirestore _firestore;

  FirestoreReminderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reminders');

  @override
  Future<void> createReminder(ReminderModel reminder) async {
    try {
      await _collection.add(reminder.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _collection.doc(reminder.id).update(reminder.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _collection.doc(reminderId).delete();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<List<ReminderModel>> streamReminders(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<ReminderModel?> getReminderById(String reminderId) async {
    try {
      final doc = await _collection.doc(reminderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ReminderModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }
}
