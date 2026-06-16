// lib/features/notifications/presentation/providers/reminder_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/repositories/reminder_repository.dart';

final remindersStreamProvider = StreamProvider<List<ReminderModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.streamReminders(user.uid);
});

class ReminderController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ReminderController(this._ref) : super(const AsyncValue.data(null));

  ReminderRepository get _repo => _ref.read(reminderRepositoryProvider);

  Future<bool> addReminder(ReminderModel reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createReminder(reminder);
      state = const AsyncValue.data(null);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }

  Future<bool> editReminder(ReminderModel reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateReminder(reminder);
      state = const AsyncValue.data(null);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }

  Future<bool> removeReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReminder(reminderId);
      state = const AsyncValue.data(null);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }
}

final reminderControllerProvider =
    StateNotifierProvider<ReminderController, AsyncValue<void>>((ref) {
  return ReminderController(ref);
});
