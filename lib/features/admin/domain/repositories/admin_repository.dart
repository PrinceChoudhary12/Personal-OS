// lib/features/admin/domain/repositories/admin_repository.dart

import '../models/announcement_model.dart';
import '../models/feedback_model.dart';

abstract class AdminRepository {
  /// Check if a UID is a founder/admin
  Future<bool> isAdmin(String uid);

  /// Platform stats
  Future<Map<String, int>> getPlatformStats();

  /// User management
  Future<List<Map<String, dynamic>>> getAllUsers();
  Future<void> deleteUser(String uid);
  Future<void> resetUserData(String uid);

  /// Announcements
  Stream<List<AnnouncementModel>> streamAnnouncements();
  Future<void> createAnnouncement(AnnouncementModel announcement);
  Future<void> deleteAnnouncement(String id);

  /// Feedback
  Stream<List<FeedbackModel>> streamFeedback();
  Future<void> deleteFeedback(String id);
}
