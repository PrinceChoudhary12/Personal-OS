// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Trigger snapshot sync on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsControllerProvider.notifier).syncAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsStreamProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final syncState = ref.watch(analyticsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync Analytics',
            onPressed: syncState.isLoading
                ? null
                : () => ref.read(analyticsControllerProvider.notifier).syncAnalytics(),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading analytics: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (analytics) {
          if (analytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No analytics snapshots found.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(analyticsControllerProvider.notifier).syncAnalytics(),
                    child: const Text('Generate Analytics Now'),
                  ),
                ],
              ),
            );
          }

          // Fetch profile target
          final profile = profileAsync.valueOrNull;
          double weeklyTargetHours = 20.0;
          if (profile != null && profile.weeklyGoalHours > 0) {
            weeklyTargetHours = profile.weeklyGoalHours;
          }

          final double totalFocusHours = analytics.totalFocusTime / 60.0;
          
          // Productivity Score calculation: (focused hours this week vs target) * 100, capped at 100
          // For score purposes, we look at the last 7 days total focus hours
          final double weeklyFocusHours = analytics.dailyProductivity.reduce((a, b) => a + b) / 60.0;
          final int productivityScore = weeklyTargetHours > 0
              ? ((weeklyFocusHours / weeklyTargetHours) * 100.0).clamp(0.0, 100.0).toInt()
              : 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Productivity Score Header ---
                    _buildProductivityScoreCard(context, productivityScore, weeklyFocusHours, weeklyTargetHours),
                    const SizedBox(height: 16),

                    // --- Focus Stats Grid ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Total Focused',
                            value: '${totalFocusHours.toStringAsFixed(1)} hrs',
                            subtitle: 'All-time focus duration',
                            color: AppColors.primary,
                            icon: Icons.hourglass_full_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Avg. Session',
                            value: '${analytics.averageSessionDuration.toStringAsFixed(0)} mins',
                            subtitle: 'Per timer session',
                            color: AppColors.secondary,
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Logged Tasks',
                            value: '${analytics.totalActivities}',
                            subtitle: 'Completed tasks',
                            color: Colors.blue,
                            icon: Icons.playlist_add_check_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Goals Rate',
                            value: '${analytics.goalCompletionRate.toStringAsFixed(0)}%',
                            subtitle: 'Goal completion',
                            color: AppColors.accent,
                            icon: Icons.emoji_events_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Tabbed Bar Charts for Productivity ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.primary,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: Colors.grey,
                            tabs: const [
                              Tab(text: '7-Day Focus (Hours)'),
                              Tab(text: 'Weekly Trend (Hours)'),
                            ],
                          ),
                          SizedBox(
                            height: 180,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildBarChart(context, analytics.dailyProductivity, ['M', 'T', 'W', 'T', 'F', 'S', 'S']),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildBarChart(context, analytics.weeklyProductivity, ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Category Distribution ---
                    _buildCategoryDistributionChart(context, analytics.categoryBreakdown, analytics.totalActivities),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductivityScoreCard(
    BuildContext context,
    int score,
    double focusedThisWeek,
    double target,
  ) {
    Color scoreColor = AppColors.error;
    String scoreLabel = 'Need Focus';
    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = 'Excellent Consistency';
    } else if (score >= 50) {
      scoreColor = AppColors.accent;
      scoreLabel = 'Good Consistency';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 8,
                    backgroundColor: scoreColor.withValues(alpha: 0.1),
                    color: scoreColor,
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Productivity Score',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed ${focusedThisWeek.toStringAsFixed(1)} of your ${target.toStringAsFixed(0)} hr target this week.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
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
    required IconData icon,
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> values, List<String> labels) {
    if (values.isEmpty) return const Center(child: Text('No productivity records found.'));
    final double maxVal = values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (idx) {
        final valMinutes = values[idx];
        final double valHours = valMinutes / 60.0;
        
        final double barHeight = maxVal > 0 
            ? (valMinutes / maxVal * 100.0).clamp(4.0, 100.0) 
            : 4.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              valHours > 0 ? '${valHours.toStringAsFixed(1)}h' : '',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: 18,
              height: barHeight,
              decoration: BoxDecoration(
                color: valMinutes > 0
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[idx],
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryDistributionChart(
    BuildContext context,
    Map<String, int> distribution,
    int totalActivities,
  ) {
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
