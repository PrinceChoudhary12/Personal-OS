// lib/features/notifications/domain/repositories/reminder_repository.dart

import '../models/reminder_model.dart';

abstract class ReminderRepository {
  Future<void> createReminder(ReminderModel reminder);
  Future<void> updateReminder(ReminderModel reminder);
  Future<void> deleteReminder(String reminderId);
  Stream<List<ReminderModel>> streamReminders(String userId);
  Future<ReminderModel?> getReminderById(String reminderId);
}
