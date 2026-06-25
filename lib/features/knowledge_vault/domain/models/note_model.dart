// lib/features/knowledge_vault/domain/models/note_model.dart

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? subject;
  final List<String> tags;
  final String category; // e.g., 'Study Note', 'General', 'Reflection', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.subject,
    required this.tags,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? subject,
    List<String>? tags,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'subject': subject,
      'tags': tags,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String docId) {
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

    final tagsRaw = map['tags'] as List<dynamic>?;
    final List<String> tagsList = tagsRaw != null ? tagsRaw.map((e) => e.toString()).toList() : [];

    return NoteModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      subject: map['subject'] as String?,
      tags: tagsList,
      category: map['category'] as String? ?? 'General',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
