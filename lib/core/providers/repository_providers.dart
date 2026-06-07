// lib/core/providers/repository_providers.dart
// NOTE: authRepositoryProvider is now defined in auth_providers.dart
// alongside the AuthController. This file retains the remaining feature
// repository stubs so they can be wired when Firebase Firestore is added.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activities/domain/repositories/activity_repository.dart';
import '../../features/focus_timer/domain/repositories/focus_session_repository.dart';
import '../../features/goals/domain/repositories/goal_repository.dart';
import '../../features/streaks/domain/repositories/streak_repository.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

// ── Stubs — will be replaced with Firestore implementations in V2 ──────────────

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  throw UnimplementedError('ActivityRepository: Firestore not yet connected.');
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  throw UnimplementedError(
      'FocusSessionRepository: Firestore not yet connected.');
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  throw UnimplementedError('GoalRepository: Firestore not yet connected.');
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  throw UnimplementedError('StreakRepository: Firestore not yet connected.');
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  throw UnimplementedError(
      'AnalyticsRepository: Firestore not yet connected.');
});
