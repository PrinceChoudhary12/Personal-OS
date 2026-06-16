// lib/core/providers/sync_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncManager extends StateNotifier<DateTime?> {
  SyncManager() : super(null);

  /// Checks if background calculations should execute (throttled to once every 15 minutes).
  bool shouldSync() {
    if (state == null) return true;
    final diff = DateTime.now().difference(state!);
    return diff.inMinutes >= 15;
  }

  /// Updates the last sync timestamp to the current time.
  void updateLastSync() {
    state = DateTime.now();
  }
}

final syncManagerProvider = StateNotifierProvider<SyncManager, DateTime?>((ref) {
  return SyncManager();
});
