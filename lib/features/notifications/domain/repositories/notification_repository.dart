// lib/features/notifications/domain/repositories/notification_repository.dart

import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationModel notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Stream<List<NotificationModel>> streamNotifications(String userId);
  Future<void> syncSystemNotifications(String userId);
}
