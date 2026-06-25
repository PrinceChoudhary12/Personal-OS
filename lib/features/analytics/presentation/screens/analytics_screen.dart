// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: AppTypography.headingLarge.copyWith(color: textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : GestureDetector(
                    onTap: () => ref.read(analyticsControllerProvider.notifier).syncAnalytics(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Sync', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (analytics) {
          if (analytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('No analytics data yet.', style: AppTypography.headingMedium.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  Text('Generate your first snapshot to get started.', style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 24),
                  AppGradientButton(
                    label: 'Generate Analytics',
                    icon: Icons.analytics_rounded,
                    onPressed: () => ref.read(analyticsControllerProvider.notifier).syncAnalytics(),
                  ),
                ],
              ),
            );
          }

          final profile = profileAsync.valueOrNull;
          double weeklyTargetHours = 20.0;
          if (profile != null && profile.weeklyGoalHours > 0) {
            weeklyTargetHours = profile.weeklyGoalHours;
          }

          final double totalFocusHours = analytics.totalFocusTime / 60.0;
          final double weeklyFocusHours = analytics.dailyProductivity.reduce((a, b) => a + b) / 60.0;
          final int productivityScore = weeklyTargetHours > 0
              ? ((weeklyFocusHours / weeklyTargetHours) * 100.0).clamp(0.0, 100.0).toInt()
              : 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Productivity Score Hero ──────────────────────────
                    _buildProductivityHero(context, productivityScore, weeklyFocusHours, weeklyTargetHours, isDark, cardColor, borderColor),
                    const SizedBox(height: 20),

                    // ── Metric Grid ──────────────────────────────────────
                    const AppSectionHeader(
                      title: 'Key Metrics',
                      icon: Icons.insights_rounded,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 480;
                        final metrics = [
                          _MetricTile(
                            title: 'Total Focused',
                            value: '${totalFocusHours.toStringAsFixed(1)}h',
                            subtitle: 'All-time focus',
                            color: AppColors.primary,
                            icon: Icons.hourglass_bottom_rounded,
                          ),
                          _MetricTile(
                            title: 'Avg. Session',
                            value: '${analytics.averageSessionDuration.toStringAsFixed(0)}m',
                            subtitle: 'Per timer session',
                            color: AppColors.accent,
                            icon: Icons.timer_outlined,
                          ),
                          _MetricTile(
                            title: 'Logged Tasks',
                            value: '${analytics.totalActivities}',
                            subtitle: 'Completed tasks',
                            color: AppColors.secondary,
                            icon: Icons.playlist_add_check_rounded,
                          ),
                          _MetricTile(
                            title: 'Goals Rate',
                            value: '${analytics.goalCompletionRate.toStringAsFixed(0)}%',
                            subtitle: 'Completion rate',
                            color: AppColors.success,
                            icon: Icons.emoji_events_outlined,
                          ),
                        ];

                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(children: [
                                Expanded(child: _buildMetricCard(context, metrics[0], cardColor, borderColor)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMetricCard(context, metrics[1], cardColor, borderColor)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _buildMetricCard(context, metrics[2], cardColor, borderColor)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMetricCard(context, metrics[3], cardColor, borderColor)),
                              ]),
                            ],
                          );
                        }
                        return Row(
                          children: metrics
                              .map((m) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: m == metrics.last ? 0 : 12),
                                      child: _buildMetricCard(context, m, cardColor, borderColor),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Trend Chart (custom pill tab bar) ─────────────────
                    const AppSectionHeader(
                      title: 'Productivity Trends',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pill tab bar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBorder.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _buildTabPill(context, 0, '7-Day Focus', isDark),
                                const SizedBox(width: 4),
                                _buildTabPill(context, 1, 'Weekly Trend', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: _selectedTab == 0
                                ? _buildBarChart(
                                    context,
                                    analytics.dailyProductivity,
                                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                                    isDark,
                                  )
                                : _buildBarChart(
                                    context,
                                    analytics.weeklyProductivity,
                                    ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'],
                                    isDark,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Category Distribution ─────────────────────────────
                    const AppSectionHeader(
                      title: 'Task Categories',
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryDistribution(context, analytics.categoryBreakdown, analytics.totalActivities, cardColor, borderColor, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabPill(BuildContext context, int index, String label, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductivityHero(
    BuildContext context,
    int score,
    double focused,
    double target,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    Color scoreColor = AppColors.error;
    String scoreLabel = 'NEEDS FOCUS';
    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = 'ELITE CONSISTENCY';
    } else if (score >= 50) {
      scoreColor = AppColors.warning;
      scoreLabel = 'STABLE PROGRESS';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Score ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withValues(alpha: 0.1),
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score',
                    style: AppTypography.numericLarge.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text('%', style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Score',
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    scoreLabel,
                    style: AppTypography.labelSmall.copyWith(color: scoreColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Completed ${focused.toStringAsFixed(1)} of your ${target.toStringAsFixed(0)} hr weekly target.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricTile tile, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tile.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tile.icon, color: tile.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            tile.value,
            style: AppTypography.numericLarge.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(tile.title, style: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary)),
          Text(tile.subtitle, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    List<double> values,
    List<String> labels,
    bool isDark,
  ) {
    if (values.isEmpty) {
      return Center(
        child: Text('No data available.', style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary)),
      );
    }
    final double maxVal = values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (idx) {
        final valMinutes = values[idx];
        final double valHours = valMinutes / 60.0;
        final double barHeight = maxVal > 0
            ? (valMinutes / maxVal * 130.0).clamp(6.0, 130.0)
            : 6.0;
        final bool hasData = valMinutes > 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasData)
              Text(
                '${valHours.toStringAsFixed(1)}h',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 9,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: hasData
                    ? AppColors.primaryGradient
                    : null,
                color: hasData
                    ? null
                    : (isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[idx],
              style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryDistribution(
    BuildContext context,
    Map<String, int> distribution,
    int totalActivities,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    final categories = ['Study', 'Coding', 'Reading', 'Gym', 'Sleep', 'Meeting', 'Project', 'Custom'];
    final categoryColors = {
      'Study': AppColors.primary,
      'Coding': AppColors.secondary,
      'Reading': AppColors.accent,
      'Gym': AppColors.warning,
      'Sleep': const Color(0xFF6366F1),
      'Meeting': const Color(0xFFEC4899),
      'Project': AppColors.success,
      'Custom': AppColors.darkTextSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalActivities == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Log activities to view category distributions.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...categories.where((cat) => (distribution[cat] ?? 0) > 0).map((cat) {
              final count = distribution[cat] ?? 0;
              final double fraction = count / totalActivities;
              final Color color = categoryColors[cat] ?? AppColors.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(cat, style: AppTypography.labelLarge.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            )),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count · ${(fraction * 100).toStringAsFixed(0)}%',
                            style: AppTypography.labelSmall.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 7,
                        backgroundColor: color.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetricTile {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}
