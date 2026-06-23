// lib/features/gamification/data/repositories/firestore_gamification_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/xp_model.dart';
import '../../domain/repositories/gamification_repository.dart';

class FirestoreGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreGamificationRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _xpCollection =>
      _firestore.collection('gamification');

  @override
  Future<XpModel?> getXp(String userId) async {
    try {
      debugPrint('🎮 [GAMIFICATION REPO] getXp called for user: $userId');
      final doc = await _xpCollection.doc(userId).get();
      if (!doc.exists) {
        debugPrint('🎮 [GAMIFICATION REPO] Document does not exist for: $userId');
        return null;
      }
      final xp = XpModel.fromMap(doc.data()!, userId);
      debugPrint('🎮 [GAMIFICATION REPO] getXp loaded: Level ${xp.level}, XP: ${xp.totalXp}');
      return xp;
    } catch (e, stack) {
      debugPrint('🚨 [GAMIFICATION REPO] Error in getXp: $e\n$stack');
      rethrow;
    }
  }

  @override
  Stream<XpModel?> watchXp(String userId) {
    debugPrint('🎮 [GAMIFICATION REPO] watchXp stream initialized for user: $userId');
    return _xpCollection.doc(userId).snapshots().map((doc) {
      debugPrint('🎮 [GAMIFICATION REPO] watchXp snapshot received. exists: ${doc.exists}');
      if (!doc.exists) {
        return null;
      }
      try {
        final xp = XpModel.fromMap(doc.data()!, userId);
        debugPrint('🎮 [GAMIFICATION REPO] watchXp parsed: Level ${xp.level}, XP: ${xp.totalXp}');
        return xp;
      } catch (e, stack) {
        debugPrint('🚨 [GAMIFICATION REPO] Error parsing XP inside stream: $e\n$stack');
        rethrow;
      }
    });
  }

  @override
  Future<void> saveXp(XpModel xp) async {
    try {
      debugPrint('🎮 [GAMIFICATION REPO] saveXp called for user: ${xp.userId}, Level: ${xp.level}, XP: ${xp.totalXp}');
      await _xpCollection.doc(xp.userId).set(
            xp.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('🎮 [GAMIFICATION REPO] saveXp completed successfully for user: ${xp.userId}');
    } catch (e, stack) {
      debugPrint('🚨 [GAMIFICATION REPO] Error saving XP: $e\n$stack');
      rethrow;
    }
  }
}
