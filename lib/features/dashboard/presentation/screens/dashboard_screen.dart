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
import '../../../../core/providers/sync_providers.dart';
import '../../../streaks/presentation/providers/streak_providers.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../ai_coach/presentation/providers/ai_coach_providers.dart';
import '../../../scheduler/presentation/providers/scheduler_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../gamification/domain/models/xp_model.dart';
import '../../../achievements/presentation/providers/achievement_providers.dart';
import '../../../achievements/domain/models/achievement_model.dart';
import '../../../daily_challenges/presentation/providers/challenge_providers.dart';
import '../../../daily_challenges/domain/models/challenge_model.dart';
import '../../../brain_games/presentation/providers/brain_games_providers.dart';
import '../../../brain_games/domain/models/game_model.dart';
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../../student_hub/presentation/providers/student_providers.dart';
import '../../../student_hub/domain/models/subject_model.dart';



class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final streakAsync = ref.watch(streakStreamProvider);
    final gamificationAsync = ref.watch(gamificationStreamProvider);
    final achievementsAsync = ref.watch(achievementsStreamProvider);
    final challengesAsync = ref.watch(dailyChallengesStreamProvider);
    final brainGamesAsync = ref.watch(brainGamesStreamProvider);
    final unreadNotifCount = ref.watch(unreadCountProvider);


    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final syncManager = ref.read(syncManagerProvider.notifier);
        if (syncManager.shouldSync()) {
          ref.read(streakRepositoryProvider).initializeStreak(user.uid);
          ref.read(streakRepositoryProvider).calculateStreakFromActivities(user.uid);
          ref.read(analyticsControllerProvider.notifier).syncAnalytics();
          ref.read(aiCoachControllerProvider.notifier).syncInsights();
          ref.read(notificationControllerProvider.notifier).syncNotifications();
          syncManager.updateLastSync();
        }
      });
    }

    final streak = streakAsync.valueOrNull?.currentStreak ?? 0;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal OS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.6),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          unreadNotifCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                  child: Badge(
                    label: Text('$unreadNotifCount'),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      tooltip: 'Notifications',
                      onPressed: () => context.push('/notifications'),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Greeting Header ---
                profileAsync.whenOrNull(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${profile?.displayName.split(' ').first ?? 'User'} 👋',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                          if (profile != null && profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              profile.bio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ) ??
                    const Text(
                      'Welcome Back 👋',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                const SizedBox(height: 16),
                _buildXPProgressCard(context, gamificationAsync),
                const SizedBox(height: 16),

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
                                const SizedBox(height: 20),
                                _buildWeeklyProgressCard(context, sessionsAsync, profileAsync),
                                const SizedBox(height: 20),
                                _buildDailyChallengesCard(context, challengesAsync),
                                const SizedBox(height: 20),
                                _buildRecentActivitiesCard(context, activitiesAsync),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildQuickActionsCard(context),
                                const SizedBox(height: 20),
                                _buildAIDailyBriefingWidget(context, ref),
                                const SizedBox(height: 20),
                                _buildAICoachCard(context, ref),
                                const SizedBox(height: 20),
                                _buildHabitsOverviewCard(context, ref),
                                const SizedBox(height: 20),
                                _buildStudentHubOverviewCard(context, ref),
                                const SizedBox(height: 20),
                                _buildRecentRemindersCard(context, ref),
                                const SizedBox(height: 20),
                                _buildUpcomingScheduleCard(context, ref),
                                const SizedBox(height: 20),
                                _buildGoalsProgressCard(context, goalsAsync),
                                const SizedBox(height: 20),
                                _buildRecentAchievementsCard(context, achievementsAsync),
                                const SizedBox(height: 20),
                                _buildBrainScoreCard(context, brainGamesAsync),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildStatsSummaryRow(context, activitiesAsync, sessionsAsync, streak),
                          const SizedBox(height: 20),
                          _buildWeeklyProgressCard(context, sessionsAsync, profileAsync),
                          const SizedBox(height: 20),
                          _buildAIDailyBriefingWidget(context, ref),
                          const SizedBox(height: 20),
                          _buildAICoachCard(context, ref),
                          const SizedBox(height: 20),
                          _buildHabitsOverviewCard(context, ref),
                          const SizedBox(height: 20),
                          _buildStudentHubOverviewCard(context, ref),
                          const SizedBox(height: 20),
                          _buildRecentRemindersCard(context, ref),
                          const SizedBox(height: 20),
                          _buildUpcomingScheduleCard(context, ref),
                          const SizedBox(height: 20),
                          _buildQuickActionsCard(context),
                          const SizedBox(height: 20),
                          _buildGoalsProgressCard(context, goalsAsync),
                          const SizedBox(height: 20),
                          _buildRecentAchievementsCard(context, achievementsAsync),
                          const SizedBox(height: 20),
                          _buildDailyChallengesCard(context, challengesAsync),
                          const SizedBox(height: 20),
                          _buildBrainScoreCard(context, brainGamesAsync),
                          const SizedBox(height: 20),
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
                    color: Colors.redAccent,
                  ),
                  _buildStatCard(
                    context,
                    width: cardWidth,
                    title: "Sessions Today",
                    value: '$todaySessionsCount',
                    icon: Icons.done_all_rounded,
                    color: AppColors.secondary,
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
                    color: Colors.blueAccent,
                  ),
                  _buildStatCard(
                    context,
                    width: cardWidth,
                    title: "Active Streak",
                    value: '$streak Days',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accent,
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
                color: Colors.redAccent,
              ),
              _buildStatCard(
                context,
                width: cardWidth,
                title: "Sessions Today",
                value: '$todaySessionsCount',
                icon: Icons.done_all_rounded,
                color: AppColors.secondary,
              ),
              _buildStatCard(
                context,
                width: cardWidth,
                title: "Logged Tasks",
                value: '$todayActivitiesCount',
                icon: Icons.checklist_outlined,
                color: Colors.blueAccent,
              ),
              _buildStatCard(
                context,
                width: cardWidth,
                title: "Active Streak",
                value: '$streak Days',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accent,
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
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
          ),
        ],
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

    double weeklyTargetHours = 20.0;
    if (profile != null && profile.weeklyGoalHours > 0) {
      weeklyTargetHours = profile.weeklyGoalHours;
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final thisWeekSessions = sessions.where((s) => s.startTime.isAfter(startOfMonday)).toList();
    final totalFocusMinutes = thisWeekSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalFocusHours = totalFocusMinutes / 60.0;

    final double completionPercent = weeklyTargetHours > 0
        ? (totalFocusHours / weeklyTargetHours).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_view_week_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Target Progress',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${totalFocusHours.toStringAsFixed(1)} / ${weeklyTargetHours.toStringAsFixed(0)} hrs focus logged',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${(completionPercent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: completionPercent,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GOALS PROGRESS CARD ---
  Widget _buildGoalsProgressCard(BuildContext context, AsyncValue<List<GoalModel>> goalsAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag_rounded, color: AppColors.secondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Goals Tracker',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/goals'),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
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
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                  const SizedBox(height: 20),
                  const Text(
                    'CURRENT GOALS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.grey, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 12),
                  ...goalsList.take(2).map((g) {
                    final percent = (g.progressPercentage / 100.0).clamp(0.0, 1.0);
                    Color pColor = AppColors.secondary;
                    if (g.isCompleted) {
                      pColor = AppColors.success;
                    } else if (g.status == 'Abandoned') {
                      pColor = Colors.grey;
                    }
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Text(
                                '${g.completedHours.toStringAsFixed(0)}/${g.targetHours.toStringAsFixed(0)} hrs (${g.progressPercentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 5,
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: pColor.withValues(alpha: 0.1),
                                color: pColor,
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.blueAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recent Activities',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/activities'),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
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
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                );
              }

              final recent = list.take(3).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final a = recent[idx];
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text('${a.category} • ${a.duration} mins', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      onTap: () => context.push('/activity/${a.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTIONS CARD ---
  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/activity/create'),
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: const Text('Log New Activity', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/timer'),
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: const Text('Start Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDailyBriefingWidget(BuildContext context, WidgetRef ref) {
    final aiInsightAsync = ref.watch(aiInsightStreamProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Daily AI Briefing',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          aiInsightAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
            error: (err, _) => Text('Error loading daily briefing: $err'),
            data: (insight) {
              if (insight == null) {
                return const Text(
                  'Daily briefing is preparing. Log a focus session or recalculate insights to generate your briefing.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.dailyBriefing,
                    style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.push('/ai-coach'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open AI Coach 2.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigoAccent,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.indigoAccent),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsOverviewCard(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cached_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Habits Today',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          habitsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Text('Error loading habits: $err'),
            data: (habits) {
              if (habits.isEmpty) {
                return Column(
                  children: [
                    const Text(
                      'No habits set up yet. Start tracking a new habit to build consistency!',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/habits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Create a Habit'),
                    ),
                  ],
                );
              }

              // Show active habits
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...habits.map((habit) {
                    final completed = habit.completedDates.contains(todayStr);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              completed
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: completed ? Color(habit.color) : Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => ref
                                .read(habitControllerProvider.notifier)
                                .toggleHabitCompletion(habit.id, todayStr),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: completed ? TextDecoration.lineThrough : null,
                                    color: completed ? Colors.grey : null,
                                  ),
                                ),
                                if (habit.description.isNotEmpty)
                                  Text(
                                    habit.description,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (habit.currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥 ', style: TextStyle(fontSize: 10)),
                                  Text(
                                    '${habit.currentStreak}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/habits'),
                    icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 16),
                    label: const Text('Manage Habits & Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAICoachCard(BuildContext context, WidgetRef ref) {
    final aiInsightAsync = ref.watch(aiInsightStreamProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.indigoAccent, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Coach Insights',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                onPressed: () => ref.read(aiCoachControllerProvider.notifier).syncInsights(),
                tooltip: 'Sync Coach Insights',
              ),
            ],
          ),
          const Divider(height: 20),
          aiInsightAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.indigoAccent),
              ),
            ),
            error: (err, _) => Text('Error loading AI insights: $err'),
            data: (insight) {
              if (insight == null) {
                return Column(
                  children: [
                    const Text(
                      'Your AI Productivity Coach is ready to analyze your habits.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(aiCoachControllerProvider.notifier).syncInsights(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Generate Coach Report'),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            insight.dailyAdvice,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WEEKLY COACH REPORT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.weeklyInsight,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SUGGESTIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  ...insight.goalSuggestions.take(2).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/ai-coach'),
                    icon: const Icon(Icons.insights_rounded, size: 14),
                    label: const Text('View Detailed Coach Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(color: Colors.indigoAccent),
                      foregroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressCard(BuildContext context, AsyncValue<XpModel?> gamificationAsync) {
    return gamificationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (xpModel) {
        if (xpModel == null) return const SizedBox.shrink();

        final level = xpModel.level;
        final totalXp = xpModel.totalXp;
        final currentXp = xpModel.currentXp;
        final nextLevelCumulativeXp = xpModel.nextLevelXp;
        
        final currentLevelBaseline = LevelCalculator.xpForLevel(level);
        final levelRange = nextLevelCumulativeXp - currentLevelBaseline;
        
        final double progress = levelRange > 0 
            ? (currentXp / levelRange).clamp(0.0, 1.0) 
            : 0.0;
            
        final xpNeeded = levelRange - currentXp;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level $level Explorer',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '$totalXp Total XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentXp / $levelRange XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$xpNeeded XP to Level ${level + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAchievementsCard(
    BuildContext context,
    AsyncValue<List<AchievementModel>> achievementsAsync,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Recent Badge',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/achievements'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            achievementsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load achievements',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
              data: (list) {
                final unlocked = list.where((a) => a.unlocked).toList();
                if (unlocked.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No badges unlocked yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete goals, tasks, or focus sessions to earn your first badge!',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  );
                }

                // Sort by unlockedAt descending
                unlocked.sort((a, b) {
                  if (a.unlockedAt == null && b.unlockedAt == null) return 0;
                  if (a.unlockedAt == null) return 1;
                  if (b.unlockedAt == null) return -1;
                  return b.unlockedAt!.compareTo(a.unlockedAt!);
                });

                final recent = unlocked.first;

                return InkWell(
                  onTap: () => context.go('/achievements'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              recent.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recent.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                recent.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengesCard(
    BuildContext context,
    AsyncValue<List<ChallengeModel>> challengesAsync,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Today's Challenges",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/daily-challenges'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            challengesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load challenges',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No challenges available today.',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  );
                }

                final completedCount = list.where((c) => c.completed).length;
                final progress = list.isNotEmpty ? completedCount / list.length : 0.0;

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...list.map((challenge) {
                      final isCompleted = challenge.completed;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isCompleted ? AppColors.primary : theme.hintColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                challenge.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? theme.hintColor : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${challenge.xpReward} XP',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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

  Widget _buildBrainScoreCard(
    BuildContext context,
    AsyncValue<List<GameModel>> brainGamesAsync,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.purpleAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Brain Score",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/brain-games'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Train Brain',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            brainGamesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load brain score',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
              data: (list) {
                final totalPlays = list.fold<int>(0, (sum, g) => sum + g.totalPlays);
                if (totalPlays == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No brain training recorded',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Play cognitive games like Reaction speed or Mental math to track your score!',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  );
                }

                final memoryRec = list.where((g) => g.gameType == 'memory_matrix').firstOrNull;
                final mathRec = list.where((g) => g.gameType == 'mental_math').firstOrNull;
                final reactionRec = list.where((g) => g.gameType == 'reaction_speed').firstOrNull;

                String memoryBest = memoryRec != null ? '${memoryRec.bestScore.toInt()} pts' : 'N/A';
                String mathBest = mathRec != null ? '${mathRec.bestScore.toInt()} pts' : 'N/A';
                String reactionBest = reactionRec != null ? '${reactionRec.bestScore.toInt()} ms' : 'N/A';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total plays: $totalPlays sessions',
                          style: TextStyle(fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active Training',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Memory Grid', memoryBest, Icons.grid_on_rounded, Colors.blueAccent),
                    const SizedBox(height: 8),
                    _buildStatRow('Reaction Speed', reactionBest, Icons.flash_on_rounded, Colors.amberAccent),
                    const SizedBox(height: 8),
                    _buildStatRow('Mental Math', mathBest, Icons.calculate_rounded, Colors.redAccent),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRemindersCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(notificationsStreamProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Upcoming Reminders",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/notifications'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            remindersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load reminders',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
              data: (list) {
                final pending = list.where((r) => !r.completed).toList();
                if (pending.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All clear! No pending reminders.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.push('/notifications'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                        ),
                        child: const Text(
                          '+ Set Reminder',
                          style: TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  );
                }

                final recent = pending.take(3).toList();

                return Column(
                  children: recent.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.completed,
                            activeColor: AppColors.secondary,
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(notificationControllerProvider.notifier).toggleCompletion(item, val);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
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

  Widget _buildStudentHubOverviewCard(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final attendanceAsync = ref.watch(attendanceStreamProvider);
    final assignmentsAsync = ref.watch(assignmentsStreamProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_outlined, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Student Hub',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                onPressed: () => context.push('/student-hub'),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          subjectsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
            error: (err, _) => Text('Error loading subjects: $err'),
            data: (subjects) {
              final attendanceLogs = attendanceAsync.valueOrNull ?? [];
              final assignments = assignmentsAsync.valueOrNull ?? [];

              // CGPA calculation
              double totalCredits = 0.0;
              double totalPoints = 0.0;
              for (final s in subjects) {
                if (s.isCompleted && s.gradePoint != null) {
                  totalCredits += s.credits;
                  totalPoints += (s.credits * s.gradePoint!);
                }
              }
              final cgpa = totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;

              // Attendance Warnings
              final lowAttendanceSubjects = <SubjectModel>[];
              for (final s in subjects) {
                final logs = attendanceLogs.where((l) => l.subjectId == s.id).toList();
                if (logs.isNotEmpty) {
                  final presents = logs.where((l) => l.status == 'present').length;
                  final absents = logs.where((l) => l.status == 'absent').length;
                  final total = presents + absents;
                  if (total > 0) {
                    final rate = (presents / total) * 100.0;
                    if (rate < 75.0) {
                      lowAttendanceSubjects.add(s);
                    }
                  }
                }
              }

              // Assignments info
              final pendingCount = assignments.where((a) => a.status == 'Pending').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT CGPA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cgpa > 0 ? cgpa.toStringAsFixed(2) : 'N/A',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'PENDING WORK',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pendingCount Assignments',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lowAttendanceSubjects.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Low attendance in ${lowAttendanceSubjects.length} subjects!',
                              style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/student-hub'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Open Student Hub', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingScheduleCard(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.teal, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                "Today's Schedule",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                onPressed: () => context.push('/scheduler'),
                tooltip: 'Open Scheduler Screen',
              ),
            ],
          ),
          const Divider(height: 20),
          schedulesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
            error: (err, _) => Text('Error loading schedule: $err'),
            data: (allSchedules) {
              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);
              final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

              final todayTasks = allSchedules
                  .where((t) => t.startTime.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
                                t.startTime.isBefore(endOfToday.add(const Duration(seconds: 1))))
                  .toList();

              if (todayTasks.isEmpty) {
                return Column(
                  children: [
                    const Text(
                      "No schedule generated for today.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/scheduler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Plan Your Day Now'),
                    ),
                  ],
                );
              }

              todayTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

              final uncompletedTasks = todayTasks
                  .where((t) => !t.completed)
                  .toList();

              final nextTask = uncompletedTasks.firstWhere(
                (t) => t.startTime.isAfter(now),
                orElse: () => uncompletedTasks.isNotEmpty ? uncompletedTasks.first : todayTasks.last,
              );

              final focusTasks = uncompletedTasks
                  .where((t) => t.category == 'Deep Work' || t.category == 'Coding')
                  .toList();
              final nextFocus = focusTasks.isNotEmpty ? focusTasks.first : null;

              final completedCount = todayTasks.where((t) => t.completed).length;
              final totalCount = todayTasks.length;
              final double completionPercent = totalCount > 0 ? completedCount / totalCount : 0.0;

              String formatTime(DateTime dt) {
                return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount / $totalCount Tasks Completed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(completionPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: completionPercent,
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_outline_rounded, color: Colors.indigo, size: 18),
                        const SizedBox(width: 10),
                        const Text('Next: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        Expanded(
                          child: Text(
                            nextTask.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatTime(nextTask.startTime),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        const Text('Focus: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        Expanded(
                          child: Text(
                            nextFocus != null ? nextFocus.title : 'None scheduled',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: nextFocus != null ? null : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (nextFocus != null)
                          Text(
                            formatTime(nextFocus.startTime),
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          val,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
