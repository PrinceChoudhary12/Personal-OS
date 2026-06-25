// lib/features/student_ai/domain/models/chat_message_model.dart

class ChatMessageModel {
  final String id;
  final String sender; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;
  final String mode; // 'generic', 'connected', 'mentor'
  final bool isError;
  final Map<String, dynamic> metadata; // optional extra data

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.mode,
    this.isError = false,
    this.metadata = const {},
  });

  ChatMessageModel copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? timestamp,
    String? mode,
    bool? isError,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      isError: isError ?? this.isError,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode,
      'isError': isError,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return ChatMessageModel(
      id: docId,
      sender: map['sender'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      timestamp: parseDate(map['timestamp']),
      mode: map['mode'] as String? ?? 'generic',
      isError: map['isError'] as bool? ?? false,
    );
  }
}
