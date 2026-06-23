// lib/features/notifications/domain/repositories/notification_repository.dart

import '../models/reminder_model.dart';

abstract class NotificationRepository {
  Stream<List<ReminderModel>> streamNotifications(String userId);
  Future<void> createNotification(ReminderModel reminder);
  Future<void> updateNotification(ReminderModel reminder);
  Future<void> deleteNotification(String id);
  Future<void> syncSystemReminders(String userId);
}
