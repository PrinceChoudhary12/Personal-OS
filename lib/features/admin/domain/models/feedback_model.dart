// lib/features/admin/domain/models/feedback_model.dart

class FeedbackModel {
  final String id;
  final String userId;
  final String type; // 'bug', 'feature', 'general'
  final String message;
  final DateTime createdAt;
  final String userEmail;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    this.userEmail = '',
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return FeedbackModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      message: map['message'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      userEmail: map['userEmail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'userEmail': userEmail,
    };
  }
}
