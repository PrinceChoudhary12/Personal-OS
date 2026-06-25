// lib/core/routing/navigation_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/gamification/presentation/providers/gamification_providers.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';

class NavigationScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const NavigationScaffold({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends ConsumerState<NavigationScaffold> {
  int? _hoveredIndex;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/activities')) return 1;
    if (location.startsWith('/timer')) return 2;
    if (location.startsWith('/goals')) return 3;
    if (location.startsWith('/streaks')) return 4;
    if (location.startsWith('/analytics')) return 5;
    if (location.startsWith('/achievements')) return 6;
    if (location.startsWith('/daily-challenges')) return 7;
    if (location.startsWith('/brain-games')) return 8;
    if (location.startsWith('/ai-coach')) return 9;
    if (location.startsWith('/student-ai')) return 10;
    if (location.startsWith('/scheduler')) return 11;
    if (location.startsWith('/student-hub')) return 12;
    if (location.startsWith('/exams')) return 13;
    if (location.startsWith('/knowledge-vault')) return 14;
    if (location.startsWith('/habits')) return 15;
    if (location.startsWith('/notifications')) return 16;
    if (location.startsWith('/admin')) return 17;
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/activities'); break;
      case 2: context.go('/timer'); break;
      case 3: context.go('/goals'); break;
      case 4: context.go('/streaks'); break;
      case 5: context.go('/analytics'); break;
      case 6: context.go('/achievements'); break;
      case 7: context.go('/daily-challenges'); break;
      case 8: context.go('/brain-games'); break;
      case 9: context.go('/ai-coach'); break;
      case 10: context.go('/student-ai'); break;
      case 11: context.go('/scheduler'); break;
      case 12: context.go('/student-hub'); break;
      case 13: context.go('/exams'); break;
      case 14: context.go('/knowledge-vault'); break;
      case 15: context.go('/habits'); break;
      case 16: context.go('/notifications'); break;
      case 17: context.go('/admin'); break;
    }
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required int activeIndex,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = index == activeIndex;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _onItemTapped(index, context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : isHovered
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.secondary.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive ? AppColors.primaryGlow : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? Colors.white
                      : isHovered
                          ? AppColors.primary
                          : AppColors.darkTextSecondary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : isHovered
                              ? AppColors.primary
                              : AppColors.darkTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
          letterSpacing: 1.1,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(
    BuildContext context, {
    required int index,
    required int activeIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = index == activeIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : AppColors.darkTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final profile = ref.watch(userProfileProvider).valueOrNull;
    final gamification = ref.watch(gamificationStreamProvider).valueOrNull;
    final userLevel = gamification?.level ?? 1;
    final totalXP = gamification?.totalXp ?? 0;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // ── Floating Sidebar ──────────────────────────────────────────
            Container(
              width: 252,
              color: AppColors.darkSidebar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: AppColors.primaryGlow,
                          ),
                          child: const Icon(
                            Icons.blur_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Personal OS',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.darkTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Nav Items (scrollable) ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        // Core
                        _buildSidebarSection('Core'),
                        _buildSidebarItem(context, index: 0, activeIndex: selectedIndex, label: 'Dashboard', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded),
                        _buildSidebarItem(context, index: 1, activeIndex: selectedIndex, label: 'Task Log', icon: Icons.check_circle_outline_rounded, activeIcon: Icons.check_circle_rounded),
                        _buildSidebarItem(context, index: 2, activeIndex: selectedIndex, label: 'Focus Timer', icon: Icons.hourglass_empty_rounded, activeIcon: Icons.hourglass_full_rounded),
                        _buildSidebarItem(context, index: 3, activeIndex: selectedIndex, label: 'Goals', icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded),
                        _buildSidebarItem(context, index: 4, activeIndex: selectedIndex, label: 'Streaks', icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_rounded),

                        // Insights
                        _buildSidebarSection('Insights'),
                        _buildSidebarItem(context, index: 5, activeIndex: selectedIndex, label: 'Analytics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
                        _buildSidebarItem(context, index: 6, activeIndex: selectedIndex, label: 'Achievements', icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded),
                        _buildSidebarItem(context, index: 7, activeIndex: selectedIndex, label: 'Daily Challenges', icon: Icons.bolt_outlined, activeIcon: Icons.bolt_rounded),

                        // Mind & AI
                        _buildSidebarSection('Mind & AI'),
                        _buildSidebarItem(context, index: 8, activeIndex: selectedIndex, label: 'Brain Games', icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded),
                        _buildSidebarItem(context, index: 9, activeIndex: selectedIndex, label: 'AI Coach', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded),
                        _buildSidebarItem(context, index: 10, activeIndex: selectedIndex, label: 'Student AI', icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded),

                        // Academic
                        _buildSidebarSection('Academic'),
                        _buildSidebarItem(context, index: 11, activeIndex: selectedIndex, label: 'Scheduler', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded),
                        _buildSidebarItem(context, index: 12, activeIndex: selectedIndex, label: 'Student Hub', icon: Icons.school_outlined, activeIcon: Icons.school_rounded),
                        _buildSidebarItem(context, index: 13, activeIndex: selectedIndex, label: 'Exam Tracker', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_turned_in_rounded),
                        _buildSidebarItem(context, index: 14, activeIndex: selectedIndex, label: 'Knowledge Vault', icon: Icons.folder_open_rounded, activeIcon: Icons.folder_rounded),

                        // Tools
                        _buildSidebarSection('Tools'),
                        _buildSidebarItem(context, index: 15, activeIndex: selectedIndex, label: 'Habits', icon: Icons.loop_rounded, activeIcon: Icons.loop_rounded),
                        _buildSidebarItem(context, index: 16, activeIndex: selectedIndex, label: 'Notifications', icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded),

                        // Founder — only visible to admin
                        if (ref.watch(isAdminProvider).valueOrNull == true) ...[
                          _buildSidebarSection('Founder'),
                          _buildSidebarItem(context, index: 17, activeIndex: selectedIndex, label: 'Admin Panel', icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings_rounded),
                        ],
                      ],
                    ),
                  ),

                  // ── Profile Card ──
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: AppColors.primaryGlow,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.darkSurface,
                              child: profile?.photoUrl != null && profile!.photoUrl.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profile.photoUrl,
                                        fit: BoxFit.cover,
                                        width: 34,
                                        height: 34,
                                      ),
                                    )
                                  : const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.displayName ?? 'Explorer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Level badge pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Lv.$userLevel  •  $totalXP XP',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Settings
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.darkBorder.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                size: 16,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content ──────────────────────────────────────────────
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // ── Mobile Floating Bottom Nav ────────────────────────────────────────
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90.0),
            child: widget.child,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.darkSidebar.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileNavItem(context, index: 0, activeIndex: selectedIndex, icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Home'),
                    _buildMobileNavItem(context, index: 1, activeIndex: selectedIndex, icon: Icons.check_circle_outline_rounded, activeIcon: Icons.check_circle_rounded, label: 'Tasks'),
                    _buildMobileNavItem(context, index: 2, activeIndex: selectedIndex, icon: Icons.hourglass_empty_rounded, activeIcon: Icons.hourglass_full_rounded, label: 'Focus'),
                    _buildMobileNavItem(context, index: 3, activeIndex: selectedIndex, icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals'),
                    _buildMobileNavItem(context, index: 4, activeIndex: selectedIndex, icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_rounded, label: 'Streaks'),
                    _buildMobileNavItem(context, index: 5, activeIndex: selectedIndex, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Stats'),
                    _buildMobileNavItem(context, index: 8, activeIndex: selectedIndex, icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: 'Brain'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
