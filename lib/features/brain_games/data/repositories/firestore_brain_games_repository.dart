// lib/features/brain_games/data/repositories/firestore_brain_games_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/game_model.dart';
import '../../domain/repositories/brain_games_repository.dart';

class FirestoreBrainGamesRepository implements BrainGamesRepository {
  final FirebaseFirestore _firestore;

  FirestoreBrainGamesRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _gamesCollection =>
      _firestore.collection('brain_games');

  String _docId(String userId, String gameType) => '${userId}_$gameType';

  @override
  Future<GameModel?> getGameScore(String userId, String gameType) async {
    try {
      debugPrint('🧠 [BRAIN GAMES REPO] getGameScore called for: $gameType, user: $userId');
      final doc = await _gamesCollection.doc(_docId(userId, gameType)).get();
      if (!doc.exists) {
        return null;
      }
      return GameModel.fromMap(doc.data()!, doc.id);
    } catch (e, stack) {
      debugPrint('🚨 [BRAIN GAMES REPO] Error in getGameScore: $e\n$stack');
      return null;
    }
  }

  @override
  Stream<List<GameModel>> watchGameScores(String userId) {
    debugPrint('🧠 [BRAIN GAMES REPO] watchGameScores stream started for user: $userId');
    return _gamesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        final list = snapshot.docs.map((doc) {
          return GameModel.fromMap(doc.data(), doc.id);
        }).toList();
        debugPrint('🧠 [BRAIN GAMES REPO] watchGameScores emitted ${list.length} game records');
        return list;
      } catch (e, stack) {
        debugPrint('🚨 [BRAIN GAMES REPO] Error mapping game scores stream: $e\n$stack');
        return [];
      }
    });
  }

  @override
  Future<void> saveGameScore(GameModel model) async {
    try {
      final docId = _docId(model.userId, model.gameType);
      debugPrint('🧠 [BRAIN GAMES REPO] saveGameScore: $docId');
      await _gamesCollection.doc(docId).set(
            model.toMap(),
            SetOptions(merge: true),
          );
    } catch (e, stack) {
      debugPrint('🚨 [BRAIN GAMES REPO] Error saving game score: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> recordGamePlay(String userId, String gameType, double score) async {
    try {
      final docId = _docId(userId, gameType);
      debugPrint('🧠 [BRAIN GAMES REPO] recordGamePlay for: $gameType, user: $userId, score: $score');
      
      final docRef = _gamesCollection.doc(docId);
      final doc = await docRef.get();
      
      final now = DateTime.now();
      if (!doc.exists) {
        final newModel = GameModel(
          userId: userId,
          gameType: gameType,
          bestScore: score,
          averageScore: score,
          totalPlays: 1,
          lastPlayed: now,
        );
        await docRef.set(newModel.toMap());
        debugPrint('🧠 [BRAIN GAMES REPO] Created initial game score record for $gameType');
      } else {
        final existing = GameModel.fromMap(doc.data()!, doc.id);
        final newTotalPlays = existing.totalPlays + 1;
        final newAverage = ((existing.averageScore * existing.totalPlays) + score) / newTotalPlays;
        
        // Lower score is better for reaction speed (milliseconds). For other games, higher score is better.
        bool isBetter = false;
        if (gameType == 'reaction_speed') {
          isBetter = existing.bestScore == 0.0 || score < existing.bestScore;
        } else {
          isBetter = score > existing.bestScore;
        }
        
        final newBest = isBetter ? score : existing.bestScore;
        
        final updated = existing.copyWith(
          bestScore: newBest,
          averageScore: newAverage,
          totalPlays: newTotalPlays,
          lastPlayed: now,
        );
        await docRef.set(updated.toMap());
        debugPrint('🧠 [BRAIN GAMES REPO] Updated game score record for $gameType (Best: $newBest, Avg: $newAverage)');
      }
    } catch (e, stack) {
      debugPrint('🚨 [BRAIN GAMES REPO] Error recording game play: $e\n$stack');
      rethrow;
    }
  }
}
