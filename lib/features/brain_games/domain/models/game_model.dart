// lib/features/brain_games/domain/models/game_model.dart

class GameModel {
  final String userId;
  final String gameType; // memory_matrix, number_recall, reaction_speed, sequence_memory, mental_math
  final double bestScore;
  final double averageScore;
  final int totalPlays;
  final DateTime lastPlayed;

  const GameModel({
    required this.userId,
    required this.gameType,
    required this.bestScore,
    required this.averageScore,
    required this.totalPlays,
    required this.lastPlayed,
  });

  GameModel copyWith({
    String? userId,
    String? gameType,
    double? bestScore,
    double? averageScore,
    int? totalPlays,
    DateTime? lastPlayed,
  }) {
    return GameModel(
      userId: userId ?? this.userId,
      gameType: gameType ?? this.gameType,
      bestScore: bestScore ?? this.bestScore,
      averageScore: averageScore ?? this.averageScore,
      totalPlays: totalPlays ?? this.totalPlays,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameType': gameType,
      'bestScore': bestScore,
      'averageScore': averageScore,
      'totalPlays': totalPlays,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return GameModel(
      userId: map['userId'] as String? ?? '',
      gameType: map['gameType'] as String? ??
          const [
            'memory_matrix',
            'number_recall',
            'reaction_speed',
            'sequence_memory',
            'mental_math'
          ].firstWhere(
            (type) => docId.endsWith(type),
            orElse: () => docId.split('_').last,
          ),
      bestScore: (map['bestScore'] as num?)?.toDouble() ?? 0.0,
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalPlays: map['totalPlays'] as int? ?? 0,
      lastPlayed: parseDate(map['lastPlayed']),
    );
  }
}
