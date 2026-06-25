// lib/features/knowledge_vault/domain/models/knowledge_item_model.dart

class KnowledgeItemModel {
  final String id;
  final String userId;
  final String type; // 'Idea', 'Task', 'Quote'
  final String content;
  final DateTime createdAt;

  const KnowledgeItemModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  KnowledgeItemModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    DateTime? createdAt,
  }) {
    return KnowledgeItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KnowledgeItemModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return KnowledgeItemModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'Idea',
      content: map['content'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
