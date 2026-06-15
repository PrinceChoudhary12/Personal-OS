// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../focus_timer/presentation/providers/focus_session_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  // Calculate focus minutes for each day of the current week (Monday - Sunday)
  List<double> _getWeeklyFocusMinutes(List<FocusSessionModel> sessions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final List<double> dailyMinutes = List.filled(7, 0.0);

    for (final s in sessions) {
      final difference = s.startTime.difference(startOfMonday).inDays;
      if (difference >= 0 && difference < 7) {
        dailyMinutes[difference] += s.durationMinutes.toDouble();
      }
    }

    return dailyMinutes;
  }

  // Calculate total activities per category
  Map<String, int> _getCategoryDistribution(List<ActivityModel> activities) {
    final Map<String, int> distribution = {};
    for (final a in activities) {
      distribution[a.category] = (distribution[a.category] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Analytics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: activitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Text('Error: $err'),
              data: (activities) {
                return sessionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Error: $err'),
                  data: (sessions) {
                    final weeklyMinutes = _getWeeklyFocusMinutes(sessions);
                    final categoryDistribution = _getCategoryDistribution(activities);

                    final totalFocusMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                    final double totalFocusHours = totalFocusMinutes / 60.0;
                    final averageMinutes = sessions.isEmpty ? 0.0 : totalFocusMinutes / sessions.length;

                    // Get weekly target from profile
                    final profile = profileAsync.valueOrNull;
                    double weeklyTargetHours = 20.0;
                    if (profile != null && profile.weeklyGoalHours > 0) {
                      weeklyTargetHours = profile.weeklyGoalHours;
                    }

                    final double completionPercent = weeklyTargetHours > 0
                        ? (totalFocusHours / weeklyTargetHours).clamp(0.0, 1.0)
                        : 1.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Metric Cards Summary ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Total Focused',
                                value: '${totalFocusHours.toStringAsFixed(1)} hrs',
                                subtitle: 'All-time sessions',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Avg. Session',
                                value: '${averageMinutes.toStringAsFixed(0)} mins',
                                subtitle: 'Focus length avg',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Weekly Target Progress Wheel ---
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CircularProgressIndicator(
                                        value: completionPercent,
                                        strokeWidth: 8,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '${(completionPercent * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Weekly Goal Progress',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Completed ${totalFocusHours.toStringAsFixed(1)} of your $weeklyTargetHours hr weekly target.',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Custom Bar Chart: Weekly Focus Hours ---
                        _buildWeeklyFocusBarChart(context, weeklyMinutes),
                        const SizedBox(height: 16),

                        // --- Horizontal Chart: Category Distribution ---
                        _buildCategoryDistributionChart(context, categoryDistribution, activities.length),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyFocusBarChart(BuildContext context, List<double> minutes) {
    final double maxVal = minutes.reduce((a, b) => a > b ? a : b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
                Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Weekly Focus Hours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final dayMinutes = minutes[idx];
                final double dayHours = dayMinutes / 60.0;
                
                // Scale height relative to maximum value, clamp at minimum 4 pixels if value is 0, maximum 120 pixels height.
                final double barHeight = maxVal > 0 
                    ? (dayMinutes / maxVal * 120.0).clamp(4.0, 120.0) 
                    : 4.0;

                return Column(
                  children: [
                    Text(
                      dayHours > 0 ? '${dayHours.toStringAsFixed(1)}h' : '',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: dayMinutes > 0
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[idx],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart(
    BuildContext context,
    Map<String, int> distribution,
    int totalActivities,
  ) {
    // Standard categories list
    final categories = ['Study', 'Coding', 'Reading', 'Gym', 'Sleep', 'Meeting', 'Project', 'Custom'];
    final categoryColors = {
      'Study': Colors.blue,
      'Coding': Colors.purple,
      'Reading': Colors.teal,
      'Gym': Colors.orange,
      'Sleep': Colors.indigo,
      'Meeting': Colors.pink,
      'Project': Colors.amber,
      'Custom': Colors.grey,
    };

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
                Icon(Icons.pie_chart_outline_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Task Category Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            if (totalActivities == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Log activities to view category distributions.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final count = distribution[cat] ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  final double fraction = count / totalActivities;
                  final Color color = categoryColors[cat] ?? AppColors.primary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              '$count (${(fraction * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: color.withValues(alpha: 0.1),
                            color: color,
                          ),
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
