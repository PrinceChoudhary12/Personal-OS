// lib/features/achievements/data/repositories/firestore_achievement_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/achievement_model.dart';
import '../../domain/repositories/achievement_repository.dart';

class FirestoreAchievementRepository implements AchievementRepository {
  final FirebaseFirestore _firestore;

  FirestoreAchievementRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _achievementsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements');
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    try {
      debugPrint('🏆 [ACHIEVEMENT REPO] getAchievements called for user: $userId');
      final querySnapshot = await _achievementsCollection(userId).get();
      final list = querySnapshot.docs.map((doc) {
        return AchievementModel.fromMap(doc.data(), doc.id);
      }).toList();
      debugPrint('🏆 [ACHIEVEMENT REPO] getAchievements loaded ${list.length} achievements');
      return list;
    } catch (e, stack) {
      debugPrint('🚨 [ACHIEVEMENT REPO] Error in getAchievements: $e\n$stack');
      return [];
    }
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    debugPrint('🏆 [ACHIEVEMENT REPO] watchAchievements stream initialized for user: $userId');
    return _achievementsCollection(userId).snapshots().map((snapshot) {
      try {
        final list = snapshot.docs.map((doc) {
          return AchievementModel.fromMap(doc.data(), doc.id);
        }).toList();
        debugPrint('🏆 [ACHIEVEMENT REPO] watchAchievements stream emitted ${list.length} achievements');
        return list;
      } catch (e, stack) {
        debugPrint('🚨 [ACHIEVEMENT REPO] Error mapping achievements inside stream: $e\n$stack');
        return [];
      }
    });
  }

  @override
  Future<void> saveAchievement(String userId, AchievementModel achievement) async {
    try {
      debugPrint('🏆 [ACHIEVEMENT REPO] saveAchievement called: ${achievement.id} for user: $userId (unlocked: ${achievement.unlocked})');
      await _achievementsCollection(userId).doc(achievement.id).set(
            achievement.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('🏆 [ACHIEVEMENT REPO] saveAchievement completed for: ${achievement.id}');
    } catch (e, stack) {
      debugPrint('🚨 [ACHIEVEMENT REPO] Error saving achievement: $e\n$stack');
      rethrow;
    }
  }
}
