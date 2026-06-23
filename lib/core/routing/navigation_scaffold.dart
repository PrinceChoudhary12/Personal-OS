// lib/core/routing/navigation_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class NavigationScaffold extends StatelessWidget {
  final Widget child;

  const NavigationScaffold({
    required this.child,
    super.key,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/activities')) {
      return 1;
    }
    if (location.startsWith('/timer')) {
      return 2;
    }
    if (location.startsWith('/goals')) {
      return 3;
    }
    if (location.startsWith('/streaks')) {
      return 4;
    }
    if (location.startsWith('/analytics')) {
      return 5;
    }
    if (location.startsWith('/achievements')) {
      return 6;
    }
    if (location.startsWith('/daily-challenges')) {
      return 7;
    }
    if (location.startsWith('/brain-games')) {
      return 8;
    }
    if (location.startsWith('/scheduler')) {
      return 9;
    }
    if (location.startsWith('/notifications')) {
      return 10;
    }
    if (location.startsWith('/ai-coach')) {
      return 11;
    }
    if (location.startsWith('/habits')) {
      return 12;
    }
    if (location.startsWith('/student-hub')) {
      return 13;
    }
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/activities');
        break;
      case 2:
        context.go('/timer');
        break;
      case 3:
        context.go('/goals');
        break;
      case 4:
        context.go('/streaks');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 6:
        context.go('/achievements');
        break;
      case 7:
        context.go('/daily-challenges');
        break;
      case 8:
        context.go('/brain-games');
        break;
      case 9:
        context.go('/scheduler');
        break;
      case 10:
        context.go('/notifications');
        break;
      case 11:
        context.go('/ai-coach');
        break;
      case 12:
        context.go('/habits');
        break;
      case 13:
        context.go('/student-hub');
        break;
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onItemTapped(index, context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : theme.hintColor,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? AppColors.primary : Colors.grey,
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

    if (isDesktop) {
      // Linear / Notion Premium Sidebar Left Layout
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Personal OS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildSidebarItem(context, index: 0, activeIndex: selectedIndex, label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
                        _buildSidebarItem(context, index: 1, activeIndex: selectedIndex, label: 'Tasks Log', icon: Icons.checklist_rtl_outlined, activeIcon: Icons.checklist_rtl),
                        _buildSidebarItem(context, index: 2, activeIndex: selectedIndex, label: 'Focus Timer', icon: Icons.timer_outlined, activeIcon: Icons.timer),
                        _buildSidebarItem(context, index: 3, activeIndex: selectedIndex, label: 'Goals Tracker', icon: Icons.tour_outlined, activeIcon: Icons.tour),
                        _buildSidebarItem(context, index: 4, activeIndex: selectedIndex, label: 'My Streaks', icon: Icons.workspace_premium_outlined, activeIcon: Icons.workspace_premium),
                        _buildSidebarItem(context, index: 5, activeIndex: selectedIndex, label: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
                        _buildSidebarItem(context, index: 6, activeIndex: selectedIndex, label: 'Achievements', icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events),
                        _buildSidebarItem(context, index: 7, activeIndex: selectedIndex, label: 'Daily Challenges', icon: Icons.bolt_outlined, activeIcon: Icons.bolt),
                        _buildSidebarItem(context, index: 8, activeIndex: selectedIndex, label: 'Brain Games', icon: Icons.psychology_outlined, activeIcon: Icons.psychology),
                        _buildSidebarItem(context, index: 9, activeIndex: selectedIndex, label: 'Smart Scheduler', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
                        _buildSidebarItem(context, index: 10, activeIndex: selectedIndex, label: 'Notifications', icon: Icons.notifications_none_outlined, activeIcon: Icons.notifications),
                        _buildSidebarItem(context, index: 11, activeIndex: selectedIndex, label: 'AI Coach', icon: Icons.psychology_outlined, activeIcon: Icons.psychology),
                        _buildSidebarItem(context, index: 12, activeIndex: selectedIndex, label: 'Habits Tracker', icon: Icons.cached_rounded, activeIcon: Icons.cached),
                        _buildSidebarItem(context, index: 13, activeIndex: selectedIndex, label: 'Student Hub', icon: Icons.school_outlined, activeIcon: Icons.school),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 16,
                            child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Personal OS Member',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.grey),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Glassmorphic Floating Bottom Navigation on Mobile
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96.0),
            child: child,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileNavItem(context, index: 0, activeIndex: selectedIndex, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
                    _buildMobileNavItem(context, index: 1, activeIndex: selectedIndex, icon: Icons.checklist_rtl_outlined, activeIcon: Icons.checklist_rtl, label: 'Tasks'),
                    _buildMobileNavItem(context, index: 2, activeIndex: selectedIndex, icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'Timer'),
                    _buildMobileNavItem(context, index: 3, activeIndex: selectedIndex, icon: Icons.tour_outlined, activeIcon: Icons.tour, label: 'Goals'),
                    _buildMobileNavItem(context, index: 4, activeIndex: selectedIndex, icon: Icons.workspace_premium_outlined, activeIcon: Icons.workspace_premium, label: 'Streaks'),
                    _buildMobileNavItem(context, index: 5, activeIndex: selectedIndex, icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Stats'),
                    _buildMobileNavItem(context, index: 6, activeIndex: selectedIndex, icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Badges'),
                    _buildMobileNavItem(context, index: 7, activeIndex: selectedIndex, icon: Icons.bolt_outlined, activeIcon: Icons.bolt, label: 'Daily'),
                    _buildMobileNavItem(context, index: 8, activeIndex: selectedIndex, icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Brain'),
                    _buildMobileNavItem(context, index: 9, activeIndex: selectedIndex, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Schedule'),
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
