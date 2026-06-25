// lib/features/knowledge_vault/domain/models/journal_model.dart

class JournalModel {
  final String id;
  final String userId;
  final String content;
  final String mood; // e.g., 'Happy', 'Productive', 'Stressed', 'Calm', 'Tired'
  final String reflection;
  final DateTime entryDate; // Normalized date representing the journal entry day
  final DateTime createdAt;

  const JournalModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.mood,
    required this.reflection,
    required this.entryDate,
    required this.createdAt,
  });

  JournalModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? mood,
    String? reflection,
    DateTime? entryDate,
    DateTime? createdAt,
  }) {
    return JournalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      reflection: reflection ?? this.reflection,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'mood': mood,
      'reflection': reflection,
      'entryDate': entryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return JournalModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      mood: map['mood'] as String? ?? 'Calm',
      reflection: map['reflection'] as String? ?? '',
      entryDate: parseDate(map['entryDate']),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
