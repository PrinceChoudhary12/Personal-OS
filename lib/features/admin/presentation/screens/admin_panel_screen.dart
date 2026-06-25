// lib/features/admin/presentation/screens/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/admin_providers.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/models/feedback_model.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return isAdminAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => _buildAccessDenied(context, textPrimary),
      data: (isAdmin) {
        if (!isAdmin) return _buildAccessDenied(context, textPrimary);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text('Admin Panel', style: AppTypography.headingLarge.copyWith(color: textPrimary)),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.darkTextSecondary,
              labelStyle: AppTypography.labelLarge,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Users'),
                Tab(text: 'Announcements'),
                Tab(text: 'Feedback'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DashboardTab(),
              _UsersTab(),
              _AnnouncementsTab(),
              _FeedbackTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context, Color textPrimary) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 56, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('Access Denied', style: AppTypography.displayMedium.copyWith(color: textPrimary)),
            const SizedBox(height: 8),
            Text(
              'This area is restricted to authorized administrators.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Founder Dashboard',
                          style: AppTypography.headingLarge.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Platform overview and management console.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats grid
                  Text('Platform Metrics', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      final tiles = [
                        _StatTile('Total Users', '${stats['totalUsers']}', Icons.people_rounded, AppColors.primary),
                        _StatTile('Active (7d)', '${stats['activeUsers']}', Icons.person_rounded, AppColors.success),
                        _StatTile('Total Goals', '${stats['totalGoals']}', Icons.flag_rounded, AppColors.warning),
                        _StatTile('Activities', '${stats['totalActivities']}', Icons.check_circle_rounded, AppColors.accent),
                        _StatTile('Total XP', '${stats['totalXP']}', Icons.star_rounded, AppColors.secondary),
                        _StatTile('Games Played', '${stats['brainGamesPlayed']}', Icons.psychology_rounded, const Color(0xFFEC4899)),
                      ];

                      if (isNarrow) {
                        return Column(
                          children: [
                            for (int i = 0; i < tiles.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(child: _buildStatTile(tiles[i], cardColor, borderColor, textPrimary)),
                                    const SizedBox(width: 12),
                                    if (i + 1 < tiles.length)
                                      Expanded(child: _buildStatTile(tiles[i + 1], cardColor, borderColor, textPrimary))
                                    else
                                      const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: tiles.map((t) => SizedBox(
                          width: (constraints.maxWidth - 28) / 3,
                          child: _buildStatTile(t, cardColor, borderColor, textPrimary),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Refresh button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(platformStatsProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Stats'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatTile(_StatTile tile, Color cardColor, Color borderColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: tile.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tile.icon, color: tile.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(tile.value, style: AppTypography.numericLarge.copyWith(color: textPrimary)),
          const SizedBox(height: 4),
          Text(tile.label, style: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

class _StatTile {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════════
// USERS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text('No users found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${users.length} Users', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(allUsersProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...users.map((u) => _buildUserCard(context, ref, u, cardColor, borderColor, textPrimary, isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    bool isDark,
  ) {
    final uid = user['uid'] as String;
    final name = user['displayName'] as String;
    final email = user['email'] as String;
    final xp = user['xp'] as int;
    final level = user['level'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.headingSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Unnamed',
                  style: AppTypography.headingSmall.copyWith(color: textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(email, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildPill('Lv.$level', AppColors.primary),
                    const SizedBox(width: 6),
                    _buildPill('$xp XP', AppColors.accent),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UID copied'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: _buildPill('UID', AppColors.darkTextSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkTextSecondary, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? AppColors.darkSurfaceCard : AppColors.lightCard,
            onSelected: (value) {
              if (value == 'delete') {
                _confirmAction(
                  context, ref,
                  'Delete User?',
                  'This will permanently remove $name and all their data.',
                  () => ref.read(adminControllerProvider.notifier).deleteUser(uid),
                );
              } else if (value == 'reset') {
                _confirmAction(
                  context, ref,
                  'Reset User Data?',
                  'This will reset all data for $name (activities, goals, XP, etc.).',
                  () => ref.read(adminControllerProvider.notifier).resetUserData(uid),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete User')),
              const PopupMenuItem(value: 'reset', child: Text('Reset Data')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontSize: 9)),
    );
  }

  void _confirmAction(BuildContext context, WidgetRef ref, String title, String body, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
              ref.invalidate(allUsersProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANNOUNCEMENTS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _AnnouncementsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends ConsumerState<_AnnouncementsTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Create announcement form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Announcement', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_titleController.text.trim().isEmpty) return;
                          await ref.read(adminControllerProvider.notifier).createAnnouncement(
                            title: _titleController.text.trim(),
                            message: _messageController.text.trim(),
                          );
                          _titleController.clear();
                          _messageController.clear();
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Existing announcements
              Text('Published', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
              const SizedBox(height: 12),
              announcementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Text('Error: $err'),
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No announcements yet.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: announcements.map((a) => _buildAnnouncementCard(a, cardColor, borderColor, textPrimary)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel a, Color cardColor, Color borderColor, Color textPrimary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.warning, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: AppTypography.headingSmall.copyWith(color: textPrimary, fontSize: 14)),
                if (a.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(a.message, style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary)),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDate(a.createdAt),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            onPressed: () => ref.read(adminControllerProvider.notifier).deleteAnnouncement(a.id),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _FeedbackTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(feedbackStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return feedbackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.feedback_outlined, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('No feedback yet.', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${items.length} Feedback Items', style: AppTypography.headingSmall.copyWith(color: textPrimary)),
                  const SizedBox(height: 14),
                  ...items.map((f) => _buildFeedbackCard(context, ref, f, cardColor, borderColor, textPrimary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    WidgetRef ref,
    FeedbackModel f,
    Color cardColor,
    Color borderColor,
    Color textPrimary,
  ) {
    Color typeColor = AppColors.primary;
    IconData typeIcon = Icons.chat_bubble_outline_rounded;
    if (f.type == 'bug') {
      typeColor = AppColors.error;
      typeIcon = Icons.bug_report_outlined;
    } else if (f.type == 'feature') {
      typeColor = AppColors.success;
      typeIcon = Icons.lightbulb_outline_rounded;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.type.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(color: typeColor, fontSize: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (f.userEmail.isNotEmpty)
                      Text(f.userEmail, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(f.message, style: AppTypography.bodySmall.copyWith(color: textPrimary)),
                const SizedBox(height: 6),
                Text(
                  _formatDate(f.createdAt),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            onPressed: () => ref.read(adminControllerProvider.notifier).deleteFeedback(f.id),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
