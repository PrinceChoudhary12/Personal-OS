// lib/features/focus_timer/data/repositories/firestore_focus_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/focus_session_model.dart';
import '../../domain/repositories/focus_repository.dart';

class FirestoreFocusRepository implements FocusRepository {
  final FirebaseFirestore _firestore;

  FirestoreFocusRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('focus_sessions');

  @override
  Future<String> createSession(FocusSessionModel session) async {
    try {
      final docRef = _collection.doc();
      final sessionWithId = session.copyWith(id: docRef.id);
      await docRef.set(sessionWithId.toMap());
      return docRef.id;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> endSession(
    String sessionId, {
    required bool completed,
    required DateTime endTime,
    required int durationMinutes,
  }) async {
    try {
      await _collection.doc(sessionId).update({
        'completed': completed,
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
      });
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<List<FocusSessionModel>> streamSessions(String userId) {
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
  Future<void> deleteSession(String sessionId) async {
    try {
      await _collection.doc(sessionId).delete();
    } catch (_) {
      rethrow;
    }
  }
}
