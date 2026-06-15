// lib/features/streaks/presentation/screens/streaks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../focus_timer/presentation/providers/focus_session_providers.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../goals/presentation/providers/goals_providers.dart';

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  int _calculateActiveStreak(List<ActivityModel> activities, List<FocusSessionModel> sessions) {
    final dates = <DateTime>{};
    for (final a in activities) {
      dates.add(DateTime(a.startTime.year, a.startTime.month, a.startTime.day));
    }
    for (final s in sessions) {
      dates.add(DateTime(s.startTime.year, s.startTime.month, s.startTime.day));
    }
    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (sortedDates.first != today && sortedDates.first != yesterday) {
      return 0;
    }

    int streak = 0;
    var checkDate = sortedDates.first;
    for (final date in sortedDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<ActivityModel> activities, List<FocusSessionModel> sessions) {
    final dates = <DateTime>{};
    for (final a in activities) {
      dates.add(DateTime(a.startTime.year, a.startTime.month, a.startTime.day));
    }
    for (final s in sessions) {
      dates.add(DateTime(s.startTime.year, s.startTime.month, s.startTime.day));
    }
    final sortedDates = dates.toList()..sort((a, b) => a.compareTo(b));
    if (sortedDates.isEmpty) return 0;

    int longest = 0;
    int current = 0;
    DateTime? prevDate;

    for (final date in sortedDates) {
      if (prevDate == null) {
        current = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          current++;
        } else if (diff > 1) {
          if (current > longest) longest = current;
          current = 1;
        }
      }
      prevDate = date;
    }

    if (current > longest) longest = current;
    return longest;
  }

  // Generate 30 days list mapping to total minutes logged on each day
  Map<DateTime, int> _generateDailyMinutes(List<ActivityModel> activities, List<FocusSessionModel> sessions) {
    final Map<DateTime, int> minutesMap = {};
    
    // Add activities duration
    for (final a in activities) {
      final date = DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      minutesMap[date] = (minutesMap[date] ?? 0) + a.duration;
    }

    // Add sessions duration
    for (final s in sessions) {
      final date = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      minutesMap[date] = (minutesMap[date] ?? 0) + s.durationMinutes;
    }

    return minutesMap;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks Engine'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Core Stats Row ---
                activitiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Error: $err'),
                  data: (activities) {
                    return sessionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, _) => Text('Error: $err'),
                      data: (sessions) {
                        final activeStreak = _calculateActiveStreak(activities, sessions);
                        final longestStreak = _calculateLongestStreak(activities, sessions);
                        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                        final double totalHours = totalMinutes / 60.0;
                        final totalTasks = activities.length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Main Cards Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStreakSummaryCard(
                                    context,
                                    title: 'Active Streak',
                                    value: '$activeStreak Days',
                                    icon: Icons.local_fire_department_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStreakSummaryCard(
                                    context,
                                    title: 'Longest Streak',
                                    value: '$longestStreak Days',
                                    icon: Icons.workspace_premium_rounded,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStreakSummaryCard(
                                    context,
                                    title: 'Focus Time',
                                    value: '${totalHours.toStringAsFixed(1)} hrs',
                                    icon: Icons.hourglass_empty_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStreakSummaryCard(
                                    context,
                                    title: 'Total Tasks',
                                    value: '$totalTasks Logged',
                                    icon: Icons.playlist_add_check_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // --- 30-Day Contribution Grid ---
                            _buildContributionSection(context, activities, sessions),
                            const SizedBox(height: 24),

                            // --- Badges Achievements ---
                            _buildAchievementsSection(context, activeStreak, longestStreak, sessions, activities, goalsAsync),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionSection(
    BuildContext context,
    List<ActivityModel> activities,
    List<FocusSessionModel> sessions,
  ) {
    final dailyMinutes = _generateDailyMinutes(activities, sessions);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // List of last 28 days + today (total 30 cells for clean grid math)
    final gridDays = List<DateTime>.generate(30, (i) {
      return today.subtract(Duration(days: 29 - i));
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_on_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Consistency Map (Last 30 Days)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: gridDays.map((day) {
                  final minutes = dailyMinutes[day] ?? 0;
                  Color cellColor = Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3);
                  
                  if (minutes > 0 && minutes <= 20) {
                    cellColor = AppColors.primary.withValues(alpha: 0.3);
                  } else if (minutes > 20 && minutes <= 60) {
                    cellColor = AppColors.primary.withValues(alpha: 0.6);
                  } else if (minutes > 60) {
                    cellColor = AppColors.primary;
                  }

                  return Tooltip(
                    message: '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}: $minutes mins logged',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: minutes > 20 ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    int activeStreak,
    int longestStreak,
    List<FocusSessionModel> sessions,
    List<ActivityModel> activities,
    AsyncValue<List<GoalModel>> goalsAsync,
  ) {
    final totalFocusSessions = sessions.length;
    final hasExtremeDeepWork = sessions.any((s) => s.durationMinutes >= 60);
    final hasLoggedTenActivities = activities.length >= 10;
    
    final goals = goalsAsync.valueOrNull ?? [];
    final hasCompletedGoal = goals.any((g) => g.status == 'Completed');

    final badgesList = [
      _Badge(
        title: 'First Focus',
        description: 'Complete 1 focus session',
        icon: Icons.gps_fixed_rounded,
        color: Colors.blue,
        isUnlocked: totalFocusSessions >= 1,
      ),
      _Badge(
        title: 'Consistency Starter',
        description: 'Reach a 3-day active streak',
        icon: Icons.local_fire_department_rounded,
        color: Colors.orange,
        isUnlocked: activeStreak >= 3,
      ),
      _Badge(
        title: 'Productivity Elite',
        description: 'Reach a 7-day streak',
        icon: Icons.workspace_premium_rounded,
        color: Colors.amber,
        isUnlocked: activeStreak >= 7 || longestStreak >= 7,
      ),
      _Badge(
        title: 'Extreme Deep Work',
        description: 'Focus 60+ minutes in a session',
        icon: Icons.bolt_rounded,
        color: Colors.purple,
        isUnlocked: hasExtremeDeepWork,
      ),
      _Badge(
        title: 'Goal Crusher',
        description: 'Complete a long-term goal',
        icon: Icons.emoji_events_rounded,
        color: Colors.green,
        isUnlocked: hasCompletedGoal,
      ),
      _Badge(
        title: 'Habit Builder',
        description: 'Log 10+ activities',
        icon: Icons.assignment_turned_in_rounded,
        color: Colors.teal,
        isUnlocked: hasLoggedTenActivities,
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Achievements & Badges',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badgesList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, idx) {
                final badge = badgesList[idx];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? badge.color.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    color: badge.isUnlocked 
                        ? badge.color.withValues(alpha: 0.05) 
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        badge.isUnlocked ? badge.icon : Icons.lock_outline_rounded,
                        color: badge.isUnlocked ? badge.color : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: badge.isUnlocked ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  _Badge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}
