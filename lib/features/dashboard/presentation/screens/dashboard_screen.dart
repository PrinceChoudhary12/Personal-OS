// lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../focus_timer/presentation/providers/focus_session_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  int _calculateStreak(List<ActivityModel> activities, List<FocusSessionModel> sessions) {
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
        // Gap in streak
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal OS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Greeting Header ---
                profileAsync.whenOrNull(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${profile?.displayName.split(' ').first ?? 'User'} 👋',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (profile != null && profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.bio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ) ??
                    Text(
                      'Welcome Back 👋',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                const SizedBox(height: 24),

                // --- Grid Layout ---
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildStatsSummaryRow(context, activitiesAsync, sessionsAsync),
                                const SizedBox(height: 16),
                                _buildWeeklyProgressCard(context, sessionsAsync, profileAsync),
                                const SizedBox(height: 16),
                                _buildRecentActivitiesCard(context, activitiesAsync),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildQuickActionsCard(context),
                                const SizedBox(height: 16),
                                _buildGoalsProgressCard(context, goalsAsync),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildStatsSummaryRow(context, activitiesAsync, sessionsAsync),
                          const SizedBox(height: 16),
                          _buildWeeklyProgressCard(context, sessionsAsync, profileAsync),
                          const SizedBox(height: 16),
                          _buildQuickActionsCard(context),
                          const SizedBox(height: 16),
                          _buildGoalsProgressCard(context, goalsAsync),
                          const SizedBox(height: 16),
                          _buildRecentActivitiesCard(context, activitiesAsync),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STATS CARDS GRID ---
  Widget _buildStatsSummaryRow(
    BuildContext context,
    AsyncValue<List<ActivityModel>> activitiesAsync,
    AsyncValue<List<FocusSessionModel>> sessionsAsync,
  ) {
    final activities = activitiesAsync.valueOrNull ?? [];
    final sessions = sessionsAsync.valueOrNull ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaySessions = sessions.where((s) => s.startTime.isAfter(today)).toList();
    final todayFocusMinutes = todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    final todayActivities = activities.where((a) => a.startTime.isAfter(today)).toList();
    final todayActivitiesCount = todayActivities.length;

    final streak = _calculateStreak(activities, sessions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 32) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard(
              context,
              width: cardWidth,
              title: "Today's Focus",
              value: '$todayFocusMinutes m',
              icon: Icons.timer_outlined,
              color: Colors.red,
            ),
            _buildStatCard(
              context,
              width: cardWidth,
              title: "Logged Tasks",
              value: '$todayActivitiesCount',
              icon: Icons.checklist_outlined,
              color: Colors.blue,
            ),
            _buildStatCard(
              context,
              width: cardWidth,
              title: "Active Streak",
              value: '$streak Days',
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required double width,
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
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- WEEKLY PROGRESS CARD ---
  Widget _buildWeeklyProgressCard(
    BuildContext context,
    AsyncValue<List<FocusSessionModel>> sessionsAsync,
    AsyncValue<dynamic> profileAsync,
  ) {
    final sessions = sessionsAsync.valueOrNull ?? [];
    final profile = profileAsync.valueOrNull;

    // Default target: 20 hours, or user profile weeklyGoalHours
    double weeklyTargetHours = 20.0;
    if (profile != null && profile.weeklyGoalHours > 0) {
      weeklyTargetHours = profile.weeklyGoalHours;
    }

    final now = DateTime.now();
    // Start of current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final thisWeekSessions = sessions.where((s) => s.startTime.isAfter(startOfMonday)).toList();
    final totalFocusMinutes = thisWeekSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalFocusHours = totalFocusMinutes / 60.0;

    final double completionPercent = weeklyTargetHours > 0
        ? (totalFocusHours / weeklyTargetHours).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_view_week, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Weekly Target Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${totalFocusHours.toStringAsFixed(1)} / ${weeklyTargetHours.toStringAsFixed(0)} hrs completed',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(completionPercent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionPercent,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GOALS PROGRESS CARD ---
  Widget _buildGoalsProgressCard(BuildContext context, AsyncValue<dynamic> goalsAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_rounded, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Goals Tracker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            goalsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary)),
              error: (err, _) => Text('Error loading goals: $err'),
              data: (goalsList) {
                final goals = List.from(goalsList);
                if (goals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No goals created yet. Set targets to keep track of key milestones.',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                // Show top 3 goals
                final displayGoals = goals.take(3).toList();
                return Column(
                  children: displayGoals.map((g) {
                    final percent = (g.progressPercentage / 100.0).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  g.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Text(
                                '${g.progressPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 4,
                              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- RECENT ACTIVITIES CARD ---
  Widget _buildRecentActivitiesCard(
      BuildContext context, AsyncValue<List<ActivityModel>> activitiesAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activities',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/activities'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 12),
            activitiesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.blue)),
              error: (err, _) => Text('Error loading recent activities: $err'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No activities logged recently.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }

                final recent = list.take(3).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final a = recent[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text('${a.category} • ${a.duration} mins'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => context.push('/activity/${a.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- QUICK ACTIONS CARD ---
  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/activity/create'),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Log New Activity'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/timer'),
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Start Focus Timer'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
