// lib/features/achievements/presentation/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../providers/achievement_providers.dart';
import '../../domain/models/achievement_model.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  late AnimationController _shimmerController;

  final List<String> _categories = ['All', 'Activities', 'Goals', 'Focus', 'Streaks', 'XP'];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: AppTypography.headingLarge.copyWith(color: textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load achievements', style: AppTypography.headingMedium.copyWith(color: textPrimary)),
            ],
          ),
        ),
        data: (achievements) {
          final unlocked = achievements.where((a) => a.unlocked).length;
          final total = achievements.length;
          final progress = total > 0 ? unlocked / total : 0.0;

          final filtered = _selectedCategory == 'All'
              ? achievements
              : achievements.where((a) => a.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Overview Hero Card ─────────────────────────────────
                    _buildOverviewHero(context, unlocked, total, progress, isDark, cardColor, borderColor),
                    const SizedBox(height: 24),

                    // ── Category Filter Chips ───────────────────────────────
                    _buildCategoryFilters(context, isDark),
                    const SizedBox(height: 20),

                    // ── Section header ─────────────────────────────────────
                    AppSectionHeader(
                      title: '$_selectedCategory Achievements',
                      subtitle: '${filtered.where((a) => a.unlocked).length} of ${filtered.length} unlocked',
                      icon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ── Achievements Grid ──────────────────────────────────
                    filtered.isEmpty
                        ? _buildEmptyState(context, isDark)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 1;
                              if (constraints.maxWidth > 800) {
                                crossAxisCount = 3;
                              } else if (constraints.maxWidth > 500) {
                                crossAxisCount = 2;
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: 148,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildAchievementCard(context, filtered[index], isDark),
                              );
                            },
                          ),
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

  Widget _buildOverviewHero(
    BuildContext context,
    int unlocked,
    int total,
    double progress,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Badges',
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked of $total badges unlocked',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.darkBorder.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTypography.numericLarge.copyWith(color: const Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : (isDark
                          ? AppColors.darkSurfaceCard
                          : AppColors.lightBorder.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementModel achievement, bool isDark) {
    final isUnlocked = achievement.unlocked;

    // Gold gradient for unlocked, frosted for locked
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      const Color(0xFFFBBF24).withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUnlocked ? null : (isDark ? AppColors.darkSurfaceCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isUnlocked ? 1.5 : 1.0,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppColors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : (isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBorder.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(14),
                      border: isUnlocked
                          ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        achievement.icon,
                        style: TextStyle(
                          fontSize: 26,
                          color: isUnlocked ? null : null,
                        ).apply(
                          color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.darkTextSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkSurfaceCard : AppColors.lightCard,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingSmall.copyWith(
                            color: isUnlocked
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                : AppColors.darkTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.darkTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isUnlocked && achievement.unlockedAt != null)
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 11, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(achievement.unlockedAt!),
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFF59E0B),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          achievement.category.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.darkTextSecondary,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements in this category',
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
