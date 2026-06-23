// lib/features/daily_challenges/presentation/providers/challenge_providers.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../focus_timer/presentation/providers/focus_providers.dart';

import '../../data/repositories/firestore_challenge_repository.dart';
import '../../domain/models/challenge_model.dart';
import '../../domain/repositories/challenge_repository.dart';

// --- Challenge Repository Provider ---
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirestoreChallengeRepository();
});

// --- Stream of Daily Challenges for the current user ---
final dailyChallengesStreamProvider = StreamProvider<List<ChallengeModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    debugPrint('⚔️ [CHALLENGE PROVIDER] No user authenticated. Returning empty list.');
    return Stream.value([]);
  }

  final repo = ref.watch(challengeRepositoryProvider);

  // Watch data sources to evaluate progress
  final activities = ref.watch(activitiesStreamProvider).valueOrNull ?? [];
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? [];
  final sessions = ref.watch(focusSessionsStreamProvider).valueOrNull ?? [];

  // Helper date logic
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 1. Calculate challenge metrics for today
  final loggedActivitiesToday = activities.where((a) => isSameDay(a.startTime, now)).length;
  
  final focusMinutesToday = sessions
      .where((s) => s.completed && isSameDay(s.startTime, now))
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);

  final updatedGoalToday = goals.any((g) => isSameDay(g.updatedAt, now));

  // 2. Logic check for each type
  bool checkProgress(String id) {
    if (id.endsWith('_activities')) {
      return loggedActivitiesToday >= 2;
    } else if (id.endsWith('_focus')) {
      return focusMinutesToday >= 30;
    } else if (id.endsWith('_goal')) {
      return updatedGoalToday;
    }
    return false;
  }

  // 3. Static definitions for today
  final staticTodayChallenges = [
    ChallengeModel(
      id: '${todayStr}_activities',
      title: 'Complete 2 activities',
      description: 'Log at least 2 tasks/activities today (Logged: $loggedActivitiesToday/2)',
      xpReward: 15,
      completed: false,
      createdAt: now,
    ),
    ChallengeModel(
      id: '${todayStr}_focus',
      title: 'Focus for 30 minutes',
      description: 'Complete focus sessions totaling 30+ minutes today (Focused: $focusMinutesToday/30m)',
      xpReward: 15,
      completed: false,
      createdAt: now,
    ),
    ChallengeModel(
      id: '${todayStr}_goal',
      title: 'Make progress on a goal',
      description: 'Update any goal details or log hours today',
      xpReward: 15,
      completed: false,
      createdAt: now,
    ),
  ];

  // 4. Merge with Firestore and auto-heal
  return repo.watchChallenges(user.uid).asyncMap((storedList) async {
    final Map<String, ChallengeModel> storedMap = {
      for (var c in storedList) c.id: c
    };

    final List<ChallengeModel> mergedList = [];
    bool hasUpdates = false;

    for (final def in staticTodayChallenges) {
      final stored = storedMap[def.id];
      final calculatedCompleted = checkProgress(def.id);

      if (stored != null) {
        if (stored.completed) {
          // Keep completed state
          mergedList.add(def.copyWith(
            completed: true,
            completedAt: stored.completedAt ?? now,
          ));
        } else if (calculatedCompleted) {
          // Progress from false to true -> save to Firestore
          final updated = def.copyWith(
            completed: true,
            completedAt: now,
          );
          mergedList.add(updated);
          hasUpdates = true;
          unawaited(repo.saveChallenge(user.uid, updated).catchError((err) {
            debugPrint('🚨 [CHALLENGE PROVIDER] Failed to auto-complete challenge ${updated.id}: $err');
          }));
        } else {
          // Stay false
          mergedList.add(def.copyWith(
            completed: false,
            completedAt: null,
          ));
        }
      } else {
        // Missing in Firestore -> create default or unlocked
        if (calculatedCompleted) {
          final updated = def.copyWith(
            completed: true,
            completedAt: now,
          );
          mergedList.add(updated);
          hasUpdates = true;
          unawaited(repo.saveChallenge(user.uid, updated).catchError((err) {
            debugPrint('🚨 [CHALLENGE PROVIDER] Failed to create completed challenge ${updated.id}: $err');
          }));
        } else {
          mergedList.add(def);
          hasUpdates = true;
          unawaited(repo.saveChallenge(user.uid, def).catchError((err) {
            debugPrint('🚨 [CHALLENGE PROVIDER] Failed to initialize daily challenge ${def.id}: $err');
          }));
        }
      }
    }

    if (hasUpdates) {
      debugPrint('⚔️ [CHALLENGE PROVIDER] Daily challenges merged and synchronized.');
    }

    return mergedList;
  });
});
