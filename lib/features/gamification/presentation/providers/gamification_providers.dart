// lib/features/gamification/presentation/providers/gamification_providers.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../focus_timer/presentation/providers/focus_providers.dart';
import '../../../daily_challenges/presentation/providers/challenge_providers.dart';
import '../../../brain_games/presentation/providers/brain_games_providers.dart';
import '../../../habits/presentation/providers/habit_providers.dart';

import '../../data/repositories/firestore_gamification_repository.dart';
import '../../domain/models/xp_model.dart';
import '../../domain/repositories/gamification_repository.dart';

// --- Gamification Repository Provider ---
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return FirestoreGamificationRepository();
});

// --- Stream of XpModel for the current user, synchronized with achievements ---
final gamificationStreamProvider = StreamProvider<XpModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    debugPrint('🎮 [GAMIFICATION PROVIDER] No user authenticated. Returning null stream.');
    return Stream.value(null);
  }

  final repo = ref.watch(gamificationRepositoryProvider);

  // Watch user actions/streams to calculate the current XP target
  final activities = ref.watch(activitiesStreamProvider).valueOrNull ?? [];
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? [];
  final sessions = ref.watch(focusSessionsStreamProvider).valueOrNull ?? [];
  final dailyChallenges = ref.watch(dailyChallengesStreamProvider).valueOrNull ?? [];
  final brainGames = ref.watch(brainGamesStreamProvider).valueOrNull ?? [];
  final habits = ref.watch(habitsStreamProvider).valueOrNull ?? [];

  // Rules:
  // Activity completed = +10 XP
  final completedActivitiesCount = activities.length;
  // Goal completed = +25 XP
  final completedGoalsCount = goals.where((g) => g.isCompleted).length;
  // Focus Session completed = +15 XP
  final completedSessionsCount = sessions.where((s) => s.completed).length;
  // Daily Challenge completed = rewards dynamic xpReward
  final completedChallengesXp = dailyChallenges
      .where((c) => c.completed)
      .fold<int>(0, (sum, c) => sum + c.xpReward);
  // Brain Game session completed = +20 XP
  final brainGamesPlays = brainGames.fold<int>(0, (sum, g) => sum + g.totalPlays);
  final completedGamesXp = brainGamesPlays * 20;
  // Habit completion checked off = +15 XP per checkoff
  final totalHabitCheckoffs = habits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
  final completedHabitsXp = totalHabitCheckoffs * 15;

  final expectedTotalXp = (completedActivitiesCount * 10) +
      (completedGoalsCount * 25) +
      (completedSessionsCount * 15) +
      completedChallengesXp +
      completedGamesXp +
      completedHabitsXp;

  final expectedLevel = LevelCalculator.calculateLevel(expectedTotalXp);
  final xpForCurrent = LevelCalculator.xpForLevel(expectedLevel);
  final xpForNext = LevelCalculator.xpForLevel(expectedLevel + 1);
  final expectedCurrentXp = expectedTotalXp - xpForCurrent;

  final now = DateTime.now();
  final expectedXpModel = XpModel(
    userId: user.uid,
    currentXp: expectedCurrentXp,
    totalXp: expectedTotalXp,
    level: expectedLevel,
    nextLevelXp: xpForNext,
    updatedAt: now,
  );

  debugPrint('🎮 [GAMIFICATION PROVIDER] Expected total XP: $expectedTotalXp, Level: $expectedLevel');

  // Listen to Firestore XP and auto-heal if out of sync
  return repo.watchXp(user.uid).asyncMap((storedModel) async {
    if (storedModel == null) {
      debugPrint('🎮 [GAMIFICATION PROVIDER] XP document not found in Firestore. Creating default...');
      repo.saveXp(expectedXpModel).catchError((err) {
        debugPrint('🚨 [GAMIFICATION PROVIDER] Failed to save initial XP: $err');
      });
      return expectedXpModel;
    }

    if (storedModel.totalXp != expectedTotalXp) {
      debugPrint('🎮 [GAMIFICATION PROVIDER] XP mismatch detected (Stored: ${storedModel.totalXp}, Calculated: $expectedTotalXp). Updating Firestore...');
      repo.saveXp(expectedXpModel).catchError((err) {
        debugPrint('🚨 [GAMIFICATION PROVIDER] Failed to update XP: $err');
      });
      return expectedXpModel;
    }

    return storedModel;
  });
});
