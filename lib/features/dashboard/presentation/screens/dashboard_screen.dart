// lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../focus_timer/presentation/providers/focus_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../streaks/presentation/providers/streak_providers.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final streakAsync = ref.watch(streakStreamProvider);

    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(streakRepositoryProvider).initializeStreak(user.uid);
        ref.read(streakRepositoryProvider).calculateStreakFromActivities(user.uid);
        ref.read(analyticsControllerProvider.notifier).syncAnalytics();
      });
    }

    final streak = streakAsync.valueOrNull?.currentStreak ?? 0;
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
                                _buildStatsSummaryRow(context, activitiesAsync, sessionsAsync, streak),
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
                          _buildStatsSummaryRow(context, activitiesAsync, sessionsAsync, streak),
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
    int streak,
  ) {
    final activities = activitiesAsync.valueOrNull ?? [];
    final sessions = sessionsAsync.valueOrNull ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaySessions = sessions.where((s) => s.startTime.isAfter(today)).toList();
    final todayFocusMinutes = todaySessions.where((s) => s.completed).fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final todaySessionsCount = todaySessions.where((s) => s.completed).length;

    final todayActivities = activities.where((a) => a.startTime.isAfter(today)).toList();
    final todayActivitiesCount = todayActivities.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          final cardWidth = (constraints.maxWidth - 16) / 2;
          return Column(
            children: [
              Row(
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
                    title: "Sessions Today",
                    value: '$todaySessionsCount',
                    icon: Icons.done_all_rounded,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
              ),
            ],
          );
        } else {
          final cardWidth = (constraints.maxWidth - 48) / 4;
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
                title: "Sessions Today",
                value: '$todaySessionsCount',
                icon: Icons.done_all_rounded,
                color: Colors.green,
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
        }
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
  Widget _buildGoalsProgressCard(BuildContext context, AsyncValue<List<GoalModel>> goalsAsync) {
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
                    Icon(Icons.flag_rounded, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Goals Tracker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/goals'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 12),
            goalsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary)),
              error: (err, _) => Text('Error loading goals: $err'),
              data: (goalsList) {
                if (goalsList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No goals created yet. Set targets to keep track of key milestones.',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                final totalGoals = goalsList.length;
                final completedGoals = goalsList.where((g) => g.isCompleted).length;
                final activeGoals = goalsList.where((g) => g.status == 'Active' && !g.isCompleted).length;
                final completionRate = totalGoals > 0 ? (completedGoals / totalGoals * 100.0) : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid of 4 stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _buildGoalMiniStat(
                          context,
                          label: 'Total Goals',
                          value: '$totalGoals',
                          icon: Icons.tour_rounded,
                          color: AppColors.primary,
                        ),
                        _buildGoalMiniStat(
                          context,
                          label: 'Completed',
                          value: '$completedGoals',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                        _buildGoalMiniStat(
                          context,
                          label: 'Active',
                          value: '$activeGoals',
                          icon: Icons.run_circle_rounded,
                          color: AppColors.accent,
                        ),
                        _buildGoalMiniStat(
                          context,
                          label: 'Completion %',
                          value: '${completionRate.toStringAsFixed(0)}%',
                          icon: Icons.pie_chart_rounded,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Display top active goal if any
                    const Text(
                      'Current Goals',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...goalsList.take(2).map((g) {
                      final percent = (g.progressPercentage / 100.0).clamp(0.0, 1.0);
                      Color pColor = AppColors.secondary;
                      if (g.isCompleted) {
                        pColor = AppColors.success;
                      } else if (g.status == 'Abandoned') {
                        pColor = Colors.grey;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${g.completedHours.toStringAsFixed(0)}/${g.targetHours.toStringAsFixed(0)} hrs (${g.progressPercentage.toStringAsFixed(0)}%)',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 4,
                                backgroundColor: pColor.withValues(alpha: 0.1),
                                color: pColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 16,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
