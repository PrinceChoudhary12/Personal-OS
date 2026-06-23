// lib/features/daily_challenges/data/repositories/firestore_challenge_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/challenge_model.dart';
import '../../domain/repositories/challenge_repository.dart';

class FirestoreChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;

  FirestoreChallengeRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _challengesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_challenges');
  }

  @override
  Future<List<ChallengeModel>> getChallenges(String userId) async {
    try {
      debugPrint('⚔️ [CHALLENGE REPO] getChallenges called for user: $userId');
      final querySnapshot = await _challengesCollection(userId).get();
      final list = querySnapshot.docs.map((doc) {
        return ChallengeModel.fromMap(doc.data(), doc.id);
      }).toList();
      debugPrint('⚔️ [CHALLENGE REPO] getChallenges loaded ${list.length} challenges');
      return list;
    } catch (e, stack) {
      debugPrint('🚨 [CHALLENGE REPO] Error in getChallenges: $e\n$stack');
      return [];
    }
  }

  @override
  Stream<List<ChallengeModel>> watchChallenges(String userId) {
    debugPrint('⚔️ [CHALLENGE REPO] watchChallenges stream initialized for user: $userId');
    return _challengesCollection(userId).snapshots().map((snapshot) {
      try {
        final list = snapshot.docs.map((doc) {
          return ChallengeModel.fromMap(doc.data(), doc.id);
        }).toList();
        debugPrint('⚔️ [CHALLENGE REPO] watchChallenges stream emitted ${list.length} challenges');
        return list;
      } catch (e, stack) {
        debugPrint('🚨 [CHALLENGE REPO] Error mapping challenges inside stream: $e\n$stack');
        return [];
      }
    });
  }

  @override
  Future<void> saveChallenge(String userId, ChallengeModel challenge) async {
    try {
      debugPrint('⚔️ [CHALLENGE REPO] saveChallenge called: ${challenge.id} for user: $userId (completed: ${challenge.completed})');
      await _challengesCollection(userId).doc(challenge.id).set(
            challenge.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('⚔️ [CHALLENGE REPO] saveChallenge completed for: ${challenge.id}');
    } catch (e, stack) {
      debugPrint('🚨 [CHALLENGE REPO] Error saving challenge: $e\n$stack');
      rethrow;
    }
  }
}
