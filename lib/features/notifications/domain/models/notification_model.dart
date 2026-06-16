// lib/features/notifications/domain/models/notification_model.dart

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'Goal', 'Focus', 'Activity', 'AI', 'General'
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
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

    return NotificationModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'General',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
