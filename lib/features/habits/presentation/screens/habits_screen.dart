// lib/features/habits/presentation/screens/habits_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/habit_model.dart';
import '../providers/habit_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  String? _selectedHabitId;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  static const List<int> _availableColors = [
    0xFF6366F1, // Indigo
    0xFF10B981, // Emerald
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFFEC4899, // Pink
    0xFF8B5CF6, // Purple
    0xFF06B6D4, // Cyan
  ];

  String _formatMonthYear(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _dateToString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditHabitDialog(context),
            tooltip: 'Add New Habit',
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cached_rounded, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No habits tracked yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a habit to begin tracking your routines and earn XP!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditHabitDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create your first habit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }

          // Auto-select first habit if selection is empty/deleted
          if (_selectedHabitId == null || !habits.any((h) => h.id == _selectedHabitId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedHabitId = habits.first.id;
              });
            });
          }

          final selectedHabit = habits.firstWhere(
            (h) => h.id == _selectedHabitId,
            orElse: () => habits.first,
          );

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildHabitsList(habits, selectedHabit),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildDetailsPanel(selectedHabit),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHabitsList(habits, selectedHabit),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                _buildDetailsPanel(selectedHabit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitsList(List<HabitModel> habits, HabitModel selectedHabit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Habits',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            final isSelected = habit.id == _selectedHabitId;

            return Card(
              elevation: 0,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                  : Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(habit.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedHabitId = habit.id;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (habit.description.isNotEmpty)
                                  Text(
                                    habit.description,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (habit.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥 ', style: TextStyle(fontSize: 10)),
                                Text(
                                  '${habit.currentStreak}d',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showAddEditHabitDialog(context, editHabit: habit);
                            } else if (val == 'delete') {
                              _confirmDeleteHabit(context, habit);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Last 7 Days',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildWeeklyTimeline(habit),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyTimeline(HabitModel habit) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((date) {
        final dateStr = _dateToString(date);
        final completed = habit.completedDates.contains(dateStr);
        final label = weekdayLabels[date.weekday % 7];
        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isToday ? AppColors.primary : Colors.grey,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => ref
                  .read(habitControllerProvider.notifier)
                  .toggleHabitCompletion(habit.id, dateStr),
              borderRadius: BorderRadius.circular(100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? Color(habit.color) : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? Color(habit.color)
                        : (isToday ? AppColors.primary : Colors.white24),
                    width: isToday ? 2.0 : 1.0,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailsPanel(HabitModel habit) {
    // Calculate Completion Rate
    final totalCheckoffs = habit.completedDates.length;
    final daysSinceCreated = DateTime.now().difference(habit.createdAt).inDays + 1;
    final compRate = daysSinceCreated > 0 ? (totalCheckoffs / daysSinceCreated * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: Color(habit.color)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          habit.frequency == 'Daily' ? 'Tracked Daily' : 'Tracked Weekly',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('Total Logged', '$totalCheckoffs', Icons.check_circle_outline_rounded, Colors.indigoAccent),
            _buildStatCard('Consistency', '$compRate%', Icons.insights_rounded, Colors.teal),
            _buildStatCard('Current Streak', '${habit.currentStreak}d', Icons.offline_bolt_rounded, Colors.orange),
            _buildStatCard('Best Streak', '${habit.longestStreak}d', Icons.emoji_events_outlined, Colors.pink),
          ],
        ),
        const SizedBox(height: 24),

        // Calendar Month view
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                        });
                      },
                    ),
                    Text(
                      _formatMonthYear(_selectedMonth),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCalendarGrid(habit),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(HabitModel habit) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final weekdayOffset = firstDay.weekday % 7;
    final totalDays = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final totalGridCells = weekdayOffset + totalDays;

    final List<String> dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Day name headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayNames
              .map((name) => Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Grid cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: totalGridCells,
          itemBuilder: (context, index) {
            if (index < weekdayOffset) {
              return const SizedBox.shrink();
            }

            final day = index - weekdayOffset + 1;
            final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
            final dateStr = _dateToString(date);
            final completed = habit.completedDates.contains(dateStr);

            final now = DateTime.now();
            final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

            return InkWell(
              onTap: () => ref
                  .read(habitControllerProvider.notifier)
                  .toggleHabitCompletion(habit.id, dateStr),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: completed ? Color(habit.color).withValues(alpha: 0.9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: completed
                        ? Color(habit.color)
                        : (isToday ? AppColors.primary : Colors.white10),
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday || completed ? FontWeight.bold : FontWeight.normal,
                      color: completed ? Colors.white : (isToday ? AppColors.primary : null),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddEditHabitDialog(BuildContext context, {HabitModel? editHabit}) {
    final titleController = TextEditingController(text: editHabit?.title ?? '');
    final descController = TextEditingController(text: editHabit?.description ?? '');
    String selectedFrequency = editHabit?.frequency ?? 'Daily';
    int selectedColor = editHabit?.color ?? _availableColors.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            editHabit != null ? 'Edit Habit' : 'Create Habit',
            style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Habit Title *',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  dropdownColor: AppColors.darkSurface,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => selectedFrequency = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Color Theme',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _availableColors.map((colorVal) {
                    final isColorSelected = colorVal == selectedColor;
                    return InkWell(
                      onTap: () => setStateDialog(() => selectedColor = colorVal),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(colorVal),
                          border: isColorSelected
                              ? Border.all(color: Colors.white, width: 2.0)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                if (user == null) return;

                if (editHabit != null) {
                  final updated = editHabit.copyWith(
                    title: title,
                    description: descController.text.trim(),
                    frequency: selectedFrequency,
                    color: selectedColor,
                    updatedAt: DateTime.now(),
                  );
                  ref.read(habitControllerProvider.notifier).editHabit(updated);
                } else {
                  final newHabit = HabitModel(
                    id: '',
                    userId: user.uid,
                    title: title,
                    description: descController.text.trim(),
                    frequency: selectedFrequency,
                    completedDates: const [],
                    color: selectedColor,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  ref.read(habitControllerProvider.notifier).addHabit(newHabit);
                }
                Navigator.pop(context);
              },
              child: Text(editHabit != null ? 'Save Changes' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Delete Habit', style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${habit.title}"? This will delete all its tracked progress.',
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(habitControllerProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
