// lib/features/notifications/presentation/providers/notification_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamNotifications(user.uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationController(this._ref) : super(const AsyncValue.data(null));

  NotificationRepository get _repo => _ref.read(notificationRepositoryProvider);

  Future<void> syncNotifications() async {
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _repo.syncSystemNotifications(user.uid);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repo.markAsRead(notificationId);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await _repo.markAllAsRead(user.uid);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repo.deleteNotification(notificationId);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> addGeneralNotification(String title, String message, String type) async {
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    try {
      final notif = NotificationModel(
        id: '',
        userId: user.uid,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _repo.createNotification(notif);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref);
});
