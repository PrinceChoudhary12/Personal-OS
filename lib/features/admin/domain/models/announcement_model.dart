// lib/features/admin/domain/models/announcement_model.dart

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return AnnouncementModel(
      id: docId,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
