// lib/features/achievements/presentation/providers/achievement_providers.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../focus_timer/presentation/providers/focus_providers.dart';
import '../../../streaks/presentation/providers/streak_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../brain_games/presentation/providers/brain_games_providers.dart';
import '../../../habits/presentation/providers/habit_providers.dart';

import '../../data/repositories/firestore_achievement_repository.dart';
import '../../domain/models/achievement_model.dart';
import '../../domain/repositories/achievement_repository.dart';

// --- Achievement Repository Provider ---
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return FirestoreAchievementRepository();
});

// --- Stream of Achievements for the current user ---
final achievementsStreamProvider = StreamProvider<List<AchievementModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    debugPrint('🏆 [ACHIEVEMENT PROVIDER] No user authenticated. Returning empty list.');
    return Stream.value([]);
  }

  final repo = ref.watch(achievementRepositoryProvider);

  // Watch data sources to compute expectations
  final activities = ref.watch(activitiesStreamProvider).valueOrNull ?? [];
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? [];
  final sessions = ref.watch(focusSessionsStreamProvider).valueOrNull ?? [];
  final streakModel = ref.watch(streakStreamProvider).valueOrNull;
  final xpModel = ref.watch(gamificationStreamProvider).valueOrNull;
  final brainGames = ref.watch(brainGamesStreamProvider).valueOrNull ?? [];
  final habits = ref.watch(habitsStreamProvider).valueOrNull ?? [];

  // 1. Calculate values
  final completedActivitiesCount = activities.length;
  final completedGoalsCount = goals.where((g) => g.isCompleted).length;
  final completedSessionsCount = sessions.where((s) => s.completed).length;

  // Sum of focus duration in hours (focus minutes / 60)
  final totalFocusHours = sessions
      .where((s) => s.completed)
      .fold<int>(0, (sum, s) => sum + s.durationMinutes) / 60.0;

  // Streak values: evaluate using the maximum of current and longest streaks to be user friendly
  final currentStreakVal = streakModel?.currentStreak ?? 0;
  final longestStreakVal = streakModel?.longestStreak ?? 0;
  final maxStreak = currentStreakVal > longestStreakVal ? currentStreakVal : longestStreakVal;

  // XP & Level values
  final totalXpVal = xpModel?.totalXp ?? 0;
  final currentLevelVal = xpModel?.level ?? 1;

  // Brain game values
  final brainGamesPlays = brainGames.fold<int>(0, (sum, g) => sum + g.totalPlays);
  final reactionSpeedRec = brainGames.where((g) => g.gameType == 'reaction_speed').firstOrNull;
  final reactionSpeedBest = reactionSpeedRec?.bestScore ?? 0.0;

  // Habit achievements values
  final totalHabitCheckoffs = habits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
  final maxHabitStreak = habits.fold<int>(0, (maxVal, h) {
    final cur = h.currentStreak;
    final lon = h.longestStreak;
    final best = cur > lon ? cur : lon;
    return best > maxVal ? best : maxVal;
  });

  // 2. Logic mapping helper
  bool isUnlocked(String id) {
    switch (id) {
      // Activities
      case 'first_activity':
        return completedActivitiesCount >= 1;
      case '10_activities':
        return completedActivitiesCount >= 10;
      case '50_activities':
        return completedActivitiesCount >= 50;
      case '100_activities':
        return completedActivitiesCount >= 100;

      // Goals
      case 'first_goal':
        return completedGoalsCount >= 1;
      case '5_goals':
        return completedGoalsCount >= 5;
      case '20_goals':
        return completedGoalsCount >= 20;

      // Focus
      case 'first_focus':
        return completedSessionsCount >= 1;
      case '10_hours_focus':
        return totalFocusHours >= 10;
      case '50_hours_focus':
        return totalFocusHours >= 50;

      // Streaks
      case '3_day_streak':
        return maxStreak >= 3;
      case '7_day_streak':
        return maxStreak >= 7;
      case '30_day_streak':
        return maxStreak >= 30;

      // XP
      case 'earn_100_xp':
        return totalXpVal >= 100;
      case 'reach_level_5':
        return currentLevelVal >= 5;
      case 'reach_level_10':
        return currentLevelVal >= 10;

      // Brain Games
      case 'first_brain_game':
        return brainGamesPlays >= 1;
      case 'brain_expert':
        return brainGamesPlays >= 10;
      case 'reaction_master':
        return reactionSpeedBest > 0.0 && reactionSpeedBest < 250.0;

      // Habits
      case 'first_habit':
        return totalHabitCheckoffs >= 1;
      case 'habit_streak_7':
        return maxHabitStreak >= 7;
      case 'habit_streak_21':
        return maxHabitStreak >= 21;

      default:
        return false;
    }
  }

  // 3. Static achievements definitions list
  final staticAchievements = [
    // Activities
    const AchievementModel(
      id: 'first_activity',
      title: 'First Activity',
      description: 'Log your first activity in Personal OS',
      icon: '🎉',
      category: 'Activities',
    ),
    const AchievementModel(
      id: '10_activities',
      title: '10 Activities',
      description: 'Log 10 activities to build consistency',
      icon: '📈',
      category: 'Activities',
    ),
    const AchievementModel(
      id: '50_activities',
      title: '50 Activities',
      description: 'Log 50 activities and stay on track',
      icon: '⚡',
      category: 'Activities',
    ),
    const AchievementModel(
      id: '100_activities',
      title: '100 Activities',
      description: 'Log 100 activities, a true power user!',
      icon: '🔥',
      category: 'Activities',
    ),

    // Goals
    const AchievementModel(
      id: 'first_goal',
      title: 'First Goal',
      description: 'Complete your first goal',
      icon: '🎯',
      category: 'Goals',
    ),
    const AchievementModel(
      id: '5_goals',
      title: '5 Goals Completed',
      description: 'Complete 5 goals successfully',
      icon: '🏆',
      category: 'Goals',
    ),
    const AchievementModel(
      id: '20_goals',
      title: '20 Goals Completed',
      description: 'Complete 20 goals and master planning',
      icon: '👑',
      category: 'Goals',
    ),

    // Focus
    const AchievementModel(
      id: 'first_focus',
      title: 'First Focus Session',
      description: 'Complete your first focus session',
      icon: '⏱️',
      category: 'Focus',
    ),
    const AchievementModel(
      id: '10_hours_focus',
      title: '10 Hours Focus',
      description: 'Focus for a total of 10 hours',
      icon: '⏳',
      category: 'Focus',
    ),
    const AchievementModel(
      id: '50_hours_focus',
      title: '50 Hours Focus',
      description: 'Focus for a total of 50 hours',
      icon: '🛸',
      category: 'Focus',
    ),

    // Brain Games (Grouped under Focus for categories view)
    const AchievementModel(
      id: 'first_brain_game',
      title: 'First Brain Game',
      description: 'Play your first brain training game',
      icon: '🧠',
      category: 'Focus',
    ),
    const AchievementModel(
      id: 'brain_expert',
      title: 'Brain Training Expert',
      description: 'Play 10 brain games to sharpen your intellect',
      icon: '⚡',
      category: 'Focus',
    ),
    const AchievementModel(
      id: 'reaction_master',
      title: 'Reaction Speed Master',
      description: 'Achieve a reaction speed best score under 250ms',
      icon: '⚡',
      category: 'Focus',
    ),

    // Streaks
    const AchievementModel(
      id: '3_day_streak',
      title: '3 Day Streak',
      description: 'Maintain a 3-day activity streak',
      icon: '🌱',
      category: 'Streaks',
    ),
    const AchievementModel(
      id: '7_day_streak',
      title: '7 Day Streak',
      description: 'Maintain a 7-day activity streak',
      icon: '🌲',
      category: 'Streaks',
    ),
    const AchievementModel(
      id: '30_day_streak',
      title: '30 Day Streak',
      description: 'Maintain a 30-day activity streak',
      icon: '🌌',
      category: 'Streaks',
    ),

    // XP
    const AchievementModel(
      id: 'earn_100_xp',
      title: 'Earn 100 XP',
      description: 'Earn a total of 100 XP',
      icon: '🪙',
      category: 'XP',
    ),
    const AchievementModel(
      id: 'reach_level_5',
      title: 'Reach Level 5',
      description: 'Advance your productivity to Level 5',
      icon: '🎖️',
      category: 'XP',
    ),
    const AchievementModel(
      id: 'reach_level_10',
      title: 'Reach Level 10',
      description: 'Advance your productivity to Level 10',
      icon: '🔮',
      category: 'XP',
    ),

    // Habits
    const AchievementModel(
      id: 'first_habit',
      title: 'First Habit Checkoff',
      description: 'Complete and check off your first habit',
      icon: '🌱',
      category: 'Habits',
    ),
    const AchievementModel(
      id: 'habit_streak_7',
      title: '7-Day Habit Streak',
      description: 'Reach a 7-day streak on any habit',
      icon: '🌲',
      category: 'Habits',
    ),
    const AchievementModel(
      id: 'habit_streak_21',
      title: '21-Day Habit Streak',
      description: 'Reach a 21-day streak on any habit to build a true habit',
      icon: '🌌',
      category: 'Habits',
    ),
  ];

  // 4. Merge static descriptions with Firestore records
  return repo.watchAchievements(user.uid).asyncMap((storedList) async {
    final Map<String, AchievementModel> storedMap = {
      for (var a in storedList) a.id: a
    };

    final List<AchievementModel> mergedList = [];
    bool hasUpdates = false;

    for (final staticDef in staticAchievements) {
      final stored = storedMap[staticDef.id];
      final calculatedUnlocked = isUnlocked(staticDef.id);

      if (stored != null) {
        if (stored.unlocked) {
          mergedList.add(staticDef.copyWith(
            unlocked: true,
            unlockedAt: stored.unlockedAt,
          ));
        } else if (calculatedUnlocked) {
          final updated = staticDef.copyWith(
            unlocked: true,
            unlockedAt: DateTime.now(),
          );
          mergedList.add(updated);
          hasUpdates = true;
          unawaited(repo.saveAchievement(user.uid, updated).catchError((err) {
            debugPrint('🚨 [ACHIEVEMENT PROVIDER] Error saving auto-unlocked achievement ${updated.id}: $err');
          }));
        } else {
          mergedList.add(staticDef.copyWith(
            unlocked: false,
            unlockedAt: null,
          ));
        }
      } else {
        if (calculatedUnlocked) {
          final updated = staticDef.copyWith(
            unlocked: true,
            unlockedAt: DateTime.now(),
          );
          mergedList.add(updated);
          hasUpdates = true;
          unawaited(repo.saveAchievement(user.uid, updated).catchError((err) {
            debugPrint('🚨 [ACHIEVEMENT PROVIDER] Error creating unlocked achievement ${updated.id}: $err');
          }));
        } else {
          mergedList.add(staticDef.copyWith(
            unlocked: false,
            unlockedAt: null,
          ));
        }
      }
    }

    if (hasUpdates) {
      debugPrint('🏆 [ACHIEVEMENT PROVIDER] Synced and unlocked new achievements for user ${user.uid}');
    }

    return mergedList;
  });
});
