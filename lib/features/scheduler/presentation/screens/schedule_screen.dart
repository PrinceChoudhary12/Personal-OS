// lib/features/scheduler/presentation/screens/schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../ai_coach/presentation/providers/ai_coach_providers.dart';
import '../../domain/models/schedule_model.dart';
import '../providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final List<String> _categories = ['Coding', 'Study', 'Workout', 'Deep Work', 'Break', 'Custom'];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Coding':
        return Colors.purple;
      case 'Study':
        return Colors.indigo;
      case 'Workout':
        return Colors.orange;
      case 'Deep Work':
        return Colors.blue;
      case 'Break':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  void _showAddTaskSheet(BuildContext context, DateTime date) {
    final titleController = TextEditingController();
    String category = 'Custom';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Time Block',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateSheet(() => category = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: startTime);
                        if (time != null) {
                          setStateSheet(() => startTime = time);
                        }
                      },
                      child: Text('Starts: ${startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: endTime);
                        if (time != null) {
                          setStateSheet(() => endTime = time);
                        }
                      },
                      child: Text('Ends: ${endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final startDt = dateOnly.add(Duration(hours: startTime.hour, minutes: startTime.minute));
                  final endDt = dateOnly.add(Duration(hours: endTime.hour, minutes: endTime.minute));

                  final newTask = ScheduledTask(
                    id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    category: category,
                    startTime: startDt,
                    endTime: endDt,
                    completed: false,
                  );

                  final scheduleState = ref.read(scheduleStreamProvider).valueOrNull;
                  if (scheduleState != null) {
                    final updatedTasks = List<ScheduledTask>.from(scheduleState.scheduledTasks)..add(newTask);
                    updatedTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
                    
                    final updatedSchedule = scheduleState.copyWith(scheduledTasks: updatedTasks);
                    ref.read(scheduleControllerProvider.notifier).saveCustomSchedule(updatedSchedule);
                  } else {
                    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                    if (user != null) {
                      final docId = '${user.uid}_${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';
                      final newSchedule = ScheduleModel(
                        id: docId,
                        userId: user.uid,
                        date: dateOnly,
                        scheduledTasks: [newTask],
                        generatedByAI: false,
                        completionStatus: 'Pending',
                        createdAt: DateTime.now(),
                      );
                      ref.read(scheduleControllerProvider.notifier).saveCustomSchedule(newSchedule);
                    }
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Block'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final scheduleAsync = ref.watch(scheduleStreamProvider);
    final aiInsightAsync = ref.watch(aiInsightStreamProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final controllerState = ref.watch(scheduleControllerProvider);

    // Generate week days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = List.generate(7, (idx) => today.add(Duration(days: idx)));

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Day Plan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'Generate Smart Schedule with AI Insights',
            onPressed: controllerState.isLoading
                ? null
                : () => controller.generateDayPlan(selectedDate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context, selectedDate),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- WEEKLY TIMELINE HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((d) {
                final isSelected = d.day == selectedDate.day && d.month == selectedDate.month && d.year == selectedDate.year;
                final dayName = weekdayNames[d.weekday - 1];

                return GestureDetector(
                  onTap: () => ref.read(selectedDateProvider.notifier).state = d,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // --- AI COACH COACHING SUGGESTIONS CARD ---
          aiInsightAsync.whenOrNull(
            data: (insight) {
              if (insight == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.indigoAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "AI Suggestion: ${insight.weeklyInsight.replaceAll('You are most productive', 'Schedule deep work')}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.indigo),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),

          // --- DAILY TIMELINE LIST ---
          Expanded(
            child: controllerState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : scheduleAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Center(child: Text('Error loading schedule: $err')),
                    data: (schedule) {
                      if (schedule == null || schedule.scheduledTasks.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 72, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No day plan compiled for this date.',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Generate a smart timeline optimized by your AI insights & active goals.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => controller.generateDayPlan(selectedDate),
                                  icon: const Icon(Icons.psychology_outlined),
                                  label: const Text('Generate Smart Day Plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final tasks = schedule.scheduledTasks;

                      return ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        onReorderItem: (oldIndex, newIndex) {
                          final List<ScheduledTask> reorderedList = List.from(tasks);
                          final item = reorderedList.removeAt(oldIndex);
                          reorderedList.insert(newIndex, item);

                          // Re-map start and end times to fit the new chronological positions
                          final List<ScheduledTask> adjustedList = [];
                          for (int i = 0; i < reorderedList.length; i++) {
                            // Assign times matching the original slot times to maintain a tidy daily timeline
                            final originalSlot = tasks[i];
                            final target = reorderedList[i];
                            
                            final duration = target.endTime.difference(target.startTime);
                            final adjustedStart = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              originalSlot.startTime.hour,
                              originalSlot.startTime.minute,
                            );

                            adjustedList.add(target.copyWith(
                              startTime: adjustedStart,
                              endTime: adjustedStart.add(duration),
                            ));
                          }

                          final updatedSchedule = schedule.copyWith(scheduledTasks: adjustedList);
                          controller.saveCustomSchedule(updatedSchedule);
                        },
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final color = _getCategoryColor(task.category);

                          return Card(
                            key: ValueKey(task.id),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: color.withValues(alpha: 0.3)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Checkbox(
                                value: task.completed,
                                activeColor: color,
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.toggleTask(selectedDate, task.id, val);
                                  }
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.completed ? TextDecoration.lineThrough : null,
                                  color: task.completed ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          task.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      final updated = List<ScheduledTask>.from(tasks)..removeAt(index);
                                      final updatedSchedule = schedule.copyWith(scheduledTasks: updated);
                                      controller.saveCustomSchedule(updatedSchedule);
                                    },
                                  ),
                                  const Icon(Icons.drag_handle_rounded, color: Colors.grey),
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
    );
  }
}
