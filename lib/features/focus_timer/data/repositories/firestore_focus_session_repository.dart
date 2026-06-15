// lib/features/focus_timer/data/repositories/firestore_focus_session_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/focus_session_model.dart';
import '../../domain/repositories/focus_session_repository.dart';

class FirestoreFocusSessionRepository implements FocusSessionRepository {
  final FirebaseFirestore _firestore;

  FirestoreFocusSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('focus_sessions');

  @override
  Stream<List<FocusSessionModel>> streamFocusSessions(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }

  @override
  Future<void> logFocusSession(FocusSessionModel session) async {
    try {
      await _collection.add(session.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<FocusSessionModel>> getSessionsInTimeRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('startTime', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      // Fallback for non-indexed range queries or alternative storage formatting:
      // Stream/retrieve all and filter programmatically to avoid requiring developer manual composite indexes.
      final snapshot = await _collection.where('userId', isEqualTo: userId).get();
      return snapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .where((s) => s.startTime.isAfter(start) && s.startTime.isBefore(end))
          .toList();
    }
  }

  @override
  Future<void> deleteFocusSession(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }
}
