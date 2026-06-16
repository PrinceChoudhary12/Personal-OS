// lib/core/providers/repository_providers.dart
// NOTE: authRepositoryProvider is now defined in auth_providers.dart
// alongside the AuthController. This file retains the remaining feature
// repository implementations wired to Firebase Firestore.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activities/data/repositories/firestore_activity_repository.dart';
import '../../features/activities/domain/repositories/activity_repository.dart';
import '../../features/focus_timer/data/repositories/firestore_focus_repository.dart';
import '../../features/focus_timer/domain/repositories/focus_repository.dart';
import '../../features/goals/data/repositories/firestore_goal_repository.dart';
import '../../features/goals/domain/repositories/goal_repository.dart';
import '../../features/streaks/data/repositories/firestore_streak_repository.dart';
import '../../features/streaks/domain/repositories/streak_repository.dart';
import '../../features/analytics/data/repositories/firestore_analytics_repository.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

// ── Firestore Implementations ──────────────────────────────────────────────────

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FirestoreActivityRepository();
});

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FirestoreFocusRepository();
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirestoreGoalRepository();
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return FirestoreStreakRepository();
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return FirestoreAnalyticsRepository();
});
