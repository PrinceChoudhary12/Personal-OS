// lib/features/goals/presentation/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/goal_model.dart';
import '../providers/goals_providers.dart';
import '../providers/goals_controllers.dart';

final goalFilterProvider = StateProvider<String>((ref) => 'All');

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, GoalModel goal) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(goalsControllerProvider.notifier).deleteGoal(goal.id);
      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Goal deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school_outlined;
      case 'Coding':
        return Icons.code_rounded;
      case 'Reading':
        return Icons.menu_book_rounded;
      case 'Gym':
        return Icons.fitness_center_rounded;
      case 'Sleep':
        return Icons.bedtime_outlined;
      case 'Meeting':
        return Icons.people_outline_rounded;
      case 'Project':
        return Icons.assignment_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final activeFilter = ref.watch(goalFilterProvider);
    final controllerState = ref.watch(goalsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals Tracker'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Filter Bar ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Active', 'Completed', 'Abandoned'].map((filter) {
                          final isSelected = activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                ref.read(goalFilterProvider.notifier).state = filter;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // --- Goals List ---
                  Expanded(
                    child: goalsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Error loading goals: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                      data: (goalsList) {
                        final filteredGoals = goalsList.where((g) {
                          if (activeFilter == 'All') return true;
                          return g.status.toLowerCase() == activeFilter.toLowerCase();
                        }).toList();

                        if (filteredGoals.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tour_outlined,
                                    size: 64,
                                    color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    activeFilter == 'All'
                                        ? 'No goals set yet.'
                                        : 'No $activeFilter goals found.',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create a new goal and start logging your progress hours!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredGoals.length,
                          itemBuilder: (context, index) {
                            final goal = filteredGoals[index];

                            Color statusColor = AppColors.primary;
                            if (goal.status == 'Completed' || goal.isCompleted) {
                              statusColor = AppColors.success;
                            } else if (goal.status == 'Abandoned') {
                              statusColor = Colors.grey;
                            }

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
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
                                    // Header: Title and Options Menu
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor.withValues(alpha: 0.1),
                                          foregroundColor: statusColor,
                                          child: Icon(_getCategoryIcon(goal.category)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      goal.isCompleted ? 'Completed' : goal.status,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    goal.category,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                goal.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              context.push('/goals/edit/${goal.id}');
                                            } else if (val == 'delete') {
                                              await _confirmDelete(context, goal);
                                            } else if (val == 'abandon') {
                                              await ref.read(goalsControllerProvider.notifier).updateGoal(
                                                    goal.copyWith(status: 'Abandoned'),
                                                  );
                                            } else if (val == 'activate') {
                                              await ref.read(goalsControllerProvider.notifier).updateGoal(
                                                    goal.copyWith(status: 'Active'),
                                                  );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            if (goal.status == 'Active' && !goal.isCompleted)
                                              const PopupMenuItem(
                                                value: 'abandon',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.block_outlined, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Abandon'),
                                                  ],
                                                ),
                                              ),
                                            if (goal.status == 'Abandoned')
                                              const PopupMenuItem(
                                                value: 'activate',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.play_arrow_outlined, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Re-activate'),
                                                  ],
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    if (goal.description.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        goal.description,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).hintColor,
                                            ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // Progress Bar and Details
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progress: ${goal.progressPercentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          '${goal.completedHours.toStringAsFixed(1)} / ${goal.targetHours.toStringAsFixed(1)} hrs',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (goal.progressPercentage / 100.0).clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: statusColor.withValues(alpha: 0.1),
                                        color: statusColor,
                                      ),
                                    ),

                                    // Interactive Quick Hours adjustment
                                    if (goal.status == 'Active' && !goal.isCompleted) ...[
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Quick Log:',
                                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: goal.completedHours > 0
                                                ? () => ref.read(goalsControllerProvider.notifier).updateGoalProgress(
                                                    goal,
                                                    (goal.completedHours - 1.0).clamp(0.0, goal.targetHours),
                                                  )
                                                : null,
                                            tooltip: 'Remove 1 hour',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: goal.completedHours < goal.targetHours
                                                ? () => ref.read(goalsControllerProvider.notifier).updateGoalProgress(
                                                    goal,
                                                    (goal.completedHours + 1.0).clamp(0.0, goal.targetHours),
                                                  )
                                                : null,
                                            tooltip: 'Add 1 hour',
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                                            label: const Text('Complete', style: TextStyle(color: AppColors.success, fontSize: 12)),
                                            onPressed: () => ref.read(goalsControllerProvider.notifier).markGoalComplete(goal),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          'Updated: ${_formatDate(goal.updatedAt)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controllerState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_road),
      ),
    );
  }
}
