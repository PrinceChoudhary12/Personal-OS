// lib/features/activities/presentation/screens/activities_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/activity_providers.dart';

final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'All');

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  final List<String> categories = const [
    'All',
    'Study',
    'Coding',
    'Reading',
    'Gym',
    'Sleep',
    'Meeting',
    'Project',
    'Custom'
  ];

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
        return Icons.groups_outlined;
      case 'Project':
        return Icons.assignment_outlined;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Study':
        return Colors.blue;
      case 'Coding':
        return Colors.purple;
      case 'Reading':
        return Colors.teal;
      case 'Gym':
        return Colors.orange;
      case 'Sleep':
        return Colors.indigo;
      case 'Meeting':
        return Colors.pink;
      case 'Project':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final selectedFilter = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities Manager'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Category Filter Selector ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = selectedFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(selectedCategoryFilterProvider.notifier).state = cat;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // --- Activities List ---
              Expanded(
                child: activitiesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading activities: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  data: (activities) {
                    final filtered = selectedFilter == 'All'
                        ? activities
                        : activities
                            .where((a) =>
                                a.category.toLowerCase() ==
                                selectedFilter.toLowerCase())
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.checklist_rounded,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFilter == 'All'
                                    ? 'Start logging your daily routines & study sessions!'
                                    : 'No activities logged under category "$selectedFilter".',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final act = filtered[index];
                        final catColor = _getCategoryColor(act.category);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: catColor.withValues(alpha: 0.12),
                              child: Icon(
                                _getCategoryIcon(act.category),
                                color: catColor,
                              ),
                            ),
                            title: Text(
                              act.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${act.duration} mins',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.label_outline_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      act.category,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (act.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    act.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 12),
                                  ),
                                ]
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push('/activity/${act.id}'),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/activity/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
