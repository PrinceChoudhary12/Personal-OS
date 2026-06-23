// test/features/brain_games/brain_games_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/brain_games/domain/models/game_model.dart';

// A local mock/fake repository to test the recordGamePlay calculations
class FakeBrainGamesRepository {
  final Map<String, GameModel> db = {};

  Future<void> recordGamePlay(String userId, String gameType, double score) async {
    final docId = '${userId}_$gameType';
    final now = DateTime.now();

    if (!db.containsKey(docId)) {
      db[docId] = GameModel(
        userId: userId,
        gameType: gameType,
        bestScore: score,
        averageScore: score,
        totalPlays: 1,
        lastPlayed: now,
      );
    } else {
      final existing = db[docId]!;
      final newTotalPlays = existing.totalPlays + 1;
      final newAverage = ((existing.averageScore * existing.totalPlays) + score) / newTotalPlays;

      bool isBetter = false;
      if (gameType == 'reaction_speed') {
        isBetter = existing.bestScore == 0.0 || score < existing.bestScore;
      } else {
        isBetter = score > existing.bestScore;
      }

      final newBest = isBetter ? score : existing.bestScore;

      db[docId] = existing.copyWith(
        bestScore: newBest,
        averageScore: newAverage,
        totalPlays: newTotalPlays,
        lastPlayed: now,
      );
    }
  }
}

void main() {
  group('GameModel Tests', () {
    test('GameModel.toMap and fromMap Serialization', () {
      final now = DateTime.now();
      final model = GameModel(
        userId: 'user_123',
        gameType: 'mental_math',
        bestScore: 150.0,
        averageScore: 120.0,
        totalPlays: 5,
        lastPlayed: now,
      );

      final map = model.toMap();
      expect(map['userId'], 'user_123');
      expect(map['gameType'], 'mental_math');
      expect(map['bestScore'], 150.0);
      expect(map['averageScore'], 120.0);
      expect(map['totalPlays'], 5);
      expect(map['lastPlayed'], now.toIso8601String());

      final deserialized = GameModel.fromMap(map, 'user_123_mental_math');
      expect(deserialized.userId, 'user_123');
      expect(deserialized.gameType, 'mental_math');
      expect(deserialized.bestScore, 150.0);
      expect(deserialized.averageScore, 120.0);
      expect(deserialized.totalPlays, 5);
      // Compare ISO 8601 string representations for timestamp sanity
      expect(deserialized.lastPlayed.toIso8601String(), now.toIso8601String());
    });

    test('GameModel.fromMap Handles Missing/Null Values Gracefully', () {
      final deserialized = GameModel.fromMap({}, 'user_abc_reaction_speed');
      expect(deserialized.userId, '');
      expect(deserialized.gameType, 'reaction_speed');
      expect(deserialized.bestScore, 0.0);
      expect(deserialized.averageScore, 0.0);
      expect(deserialized.totalPlays, 0);
      expect(deserialized.lastPlayed, isA<DateTime>());
    });

    test('GameModel.copyWith copies correctly', () {
      final now = DateTime.now();
      final original = GameModel(
        userId: 'user_1',
        gameType: 'memory_matrix',
        bestScore: 50.0,
        averageScore: 40.0,
        totalPlays: 2,
        lastPlayed: now,
      );

      final updated = original.copyWith(bestScore: 60.0, totalPlays: 3);
      expect(updated.userId, 'user_1');
      expect(updated.gameType, 'memory_matrix');
      expect(updated.bestScore, 60.0);
      expect(updated.averageScore, 40.0);
      expect(updated.totalPlays, 3);
      expect(updated.lastPlayed, now);
    });
  });

  group('Brain Games Score Recording Math Tests', () {
    late FakeBrainGamesRepository repo;

    setUp(() {
      repo = FakeBrainGamesRepository();
    });

    test('First recorded play creates record with score as best and average', () async {
      await repo.recordGamePlay('user_1', 'mental_math', 10.0);
      const docId = 'user_1_mental_math';

      expect(repo.db.containsKey(docId), true);
      final entry = repo.db[docId]!;
      expect(entry.bestScore, 10.0);
      expect(entry.averageScore, 10.0);
      expect(entry.totalPlays, 1);
    });

    test('Subsequent plays correctly update total plays, average, and best score (higher is better)', () async {
      await repo.recordGamePlay('user_1', 'mental_math', 10.0); // Play 1: 10
      await repo.recordGamePlay('user_1', 'mental_math', 20.0); // Play 2: 20 (better)
      await repo.recordGamePlay('user_1', 'mental_math', 15.0); // Play 3: 15 (worse)

      final entry = repo.db['user_1_mental_math']!;
      expect(entry.totalPlays, 3);
      expect(entry.bestScore, 20.0);
      // Avg: (10 + 20 + 15) / 3 = 15.0
      expect(entry.averageScore, 15.0);
    });

    test('Reaction Speed treats lower scores as better best scores', () async {
      await repo.recordGamePlay('user_1', 'reaction_speed', 300.0); // Play 1: 300ms
      await repo.recordGamePlay('user_1', 'reaction_speed', 220.0); // Play 2: 220ms (better)
      await repo.recordGamePlay('user_1', 'reaction_speed', 250.0); // Play 3: 250ms (worse)

      final entry = repo.db['user_1_reaction_speed']!;
      expect(entry.totalPlays, 3);
      expect(entry.bestScore, 220.0);
      // Avg: (300 + 220 + 250) / 3 = 256.67
      expect(entry.averageScore, closeTo(256.67, 0.01));
    });
  });
}
