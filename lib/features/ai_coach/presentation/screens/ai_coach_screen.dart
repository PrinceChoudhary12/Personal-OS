// lib/features/ai_coach/presentation/screens/ai_coach_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/ai_coach_providers.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> with SingleTickerProviderStateMixin {
  late TabController _summaryTabController;

  @override
  void initState() {
    super.initState();
    _summaryTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _summaryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiInsightAsync = ref.watch(aiInsightStreamProvider);
    final syncState = ref.watch(aiCoachControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Productivity Coach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Recalculate AI Report',
            onPressed: syncState.isLoading
                ? null
                : () => ref.read(aiCoachControllerProvider.notifier).syncInsights(),
          ),
        ],
      ),
      body: aiInsightAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.indigoAccent),
        ),
        error: (err, _) => Center(
          child: Text('Error loading coach: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (insight) {
          if (insight == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology_outlined, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No AI insights calculated yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to analyze your productivity databases.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.read(aiCoachControllerProvider.notifier).syncInsights(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Analyze Productivity now'),
                  ),
                ],
              ),
            );
          }

          // Compute Productivity Color
          Color scoreColor = Colors.red;
          String scoreLabel = 'Needs Momentum';
          if (insight.productivityScore >= 80) {
            scoreColor = Colors.green;
            scoreLabel = 'High Consistency';
          } else if (insight.productivityScore >= 50) {
            scoreColor = Colors.orange;
            scoreLabel = 'Good Consistency';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Productivity Score Progress Gauge ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: insight.productivityScore / 100.0,
                                    strokeWidth: 12,
                                    backgroundColor: scoreColor.withValues(alpha: 0.1),
                                    color: scoreColor,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${insight.productivityScore}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                                    ),
                                    const Text(
                                      'SCORE',
                                      style: TextStyle(fontSize: 10, letterSpacing: 2.0, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              scoreLabel,
                              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Calculated across Focus Time, Goal progress, Tasks logs, and Active Streaks.',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Daily Advice & Warnings Box ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Advice',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Divider(height: 20),
                            // Advice row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DAILY ADVICE',
                                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        insight.dailyAdvice,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Insight row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.psychology, color: Colors.indigo, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WEEKLY COACH INSIGHT',
                                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        insight.weeklyInsight,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Warnings list
                            const Text(
                              'PRODUCTIVITY WARNINGS',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            ...insight.productivityWarnings.map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        w.contains('warnings') || w.contains('balance')
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.warning_amber_rounded,
                                        color: w.contains('warnings') || w.contains('balance') ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(w, style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Productivity Summary Tabs ---
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
                            controller: _summaryTabController,
                            indicatorColor: Colors.indigoAccent,
                            labelColor: Colors.indigoAccent,
                            unselectedLabelColor: Colors.grey,
                            tabs: const [
                              Tab(text: 'Daily Summary'),
                              Tab(text: 'Weekly summary'),
                              Tab(text: 'Monthly summary'),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 120,
                            child: TabBarView(
                              controller: _summaryTabController,
                              children: [
                                Text(insight.dailySummary, style: const TextStyle(fontSize: 13, height: 1.4)),
                                Text(insight.weeklySummary, style: const TextStyle(fontSize: 13, height: 1.4)),
                                Text(insight.monthlySummary, style: const TextStyle(fontSize: 13, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Comparative Performance Graph (This Week vs Last Week) ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Comparison',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              'Visualizing focus time and tasks logs compared to the prior week period.',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 24),
                            _buildComparisonChart(context, insight.trendComparison),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Improvement Areas ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildListCard(
                            context,
                            title: 'Focus Improvement',
                            icon: Icons.track_changes_rounded,
                            iconColor: Colors.teal,
                            items: insight.focusImprovementTips,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildListCard(
                            context,
                            title: 'Time Management',
                            icon: Icons.hourglass_top_rounded,
                            iconColor: Colors.deepPurple,
                            items: insight.timeManagementSuggestions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildListCard(
                      context,
                      title: 'Goal Recommendations',
                      icon: Icons.flag_rounded,
                      iconColor: Colors.pink,
                      items: insight.goalRecommendations,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonChart(BuildContext context, Map<String, dynamic> trends) {
    final double thisWeekMins = (trends['thisWeekFocusMinutes'] as num?)?.toDouble() ?? 0.0;
    final double lastWeekMins = (trends['lastWeekFocusMinutes'] as num?)?.toDouble() ?? 0.0;
    final double thisWeekMinsHours = thisWeekMins / 60.0;
    final double lastWeekMinsHours = lastWeekMins / 60.0;

    final double thisWeekTasks = (trends['thisWeekActivities'] as num?)?.toDouble() ?? 0.0;
    final double lastWeekTasks = (trends['lastWeekActivities'] as num?)?.toDouble() ?? 0.0;

    final double maxFocus = thisWeekMinsHours > lastWeekMinsHours ? (thisWeekMinsHours > 0 ? thisWeekMinsHours : 1.0) : (lastWeekMinsHours > 0 ? lastWeekMinsHours : 1.0);
    final double maxTasks = thisWeekTasks > lastWeekTasks ? (thisWeekTasks > 0 ? thisWeekTasks : 1.0) : (lastWeekTasks > 0 ? lastWeekTasks : 1.0);

    return Column(
      children: [
        // Focus Hours Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              child: Text(
                'Focus Hours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  // This week bar
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: (thisWeekMinsHours / maxFocus * 120.0).clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${thisWeekMinsHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last week bar
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: (lastWeekMinsHours / maxFocus * 120.0).clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${lastWeekMinsHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tasks Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              child: Text(
                'Tasks Logged',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  // This week bar
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: (thisWeekTasks / maxTasks * 120.0).clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${thisWeekTasks.toInt()}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last week bar
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: (lastWeekTasks / maxTasks * 120.0).clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${lastWeekTasks.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(Colors.indigoAccent, 'This Week Focus'),
            const SizedBox(width: 12),
            _buildLegendDot(Colors.teal, 'This Week Tasks'),
            const SizedBox(width: 12),
            _buildLegendDot(Colors.grey[400]!, 'Prior Week'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildListCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
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
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 16),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          it,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
