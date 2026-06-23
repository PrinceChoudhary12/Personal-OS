// lib/features/notifications/presentation/providers/notification_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationsStreamProvider = StreamProvider<List<ReminderModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }

  final repo = ref.watch(notificationRepositoryProvider);
  
  // Background trigger of smart warnings sync
  repo.syncSystemReminders(user.uid).catchError((_) {});
  
  return repo.streamNotifications(user.uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.valueOrNull?.where((r) => !r.completed).length ?? 0;
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationController(this._ref) : super(const AsyncValue.data(null));

  NotificationRepository get _repo => _ref.read(notificationRepositoryProvider);

  Future<void> addReminder(ReminderModel reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createNotification(reminder);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editReminder(ReminderModel reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateNotification(reminder);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteReminder(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteNotification(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleCompletion(ReminderModel reminder, bool completed) async {
    final updated = reminder.copyWith(completed: completed);
    await editReminder(updated);
  }

  Future<void> syncReminders() async {
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _repo.syncSystemReminders(user.uid);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> addGeneralNotification(
    String title,
    String message,
    String type,
  ) async {
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    final reminder = ReminderModel(
      id: '',
      userId: user.uid,
      title: title,
      description: message,
      reminderTime: DateTime.now(),
      type: type,
      completed: false,
      createdAt: DateTime.now(),
    );
    await addReminder(reminder);
  }

  Future<void> syncNotifications() async {
    await syncReminders();
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref);
});
