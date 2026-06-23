// lib/features/scheduler/presentation/screens/scheduler_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/scheduler_model.dart';
import '../providers/scheduler_providers.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Deep Work',
    'Coding',
    'Design',
    'Workout',
    'Rest/Break',
    'Meeting',
    'Learning',
    'Custom'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.accent;
      default:
        return AppColors.secondary;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Deep Work':
        return Colors.indigoAccent;
      case 'Coding':
        return Colors.purpleAccent;
      case 'Design':
        return Colors.pinkAccent;
      case 'Workout':
        return Colors.orangeAccent;
      case 'Rest/Break':
        return Colors.tealAccent;
      case 'Meeting':
        return Colors.blueAccent;
      case 'Learning':
        return Colors.amberAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddEditSheet(BuildContext context, {SchedulerModel? editTask}) {
    final titleController = TextEditingController(text: editTask?.title ?? '');
    String selectedCategory = editTask?.category ?? 'Coding';
    String selectedPriority = editTask?.priority ?? 'Medium';

    TimeOfDay startTime = editTask != null
        ? TimeOfDay(hour: editTask.startTime.hour, minute: editTask.startTime.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay endTime = editTask != null
        ? TimeOfDay(hour: editTask.endTime.hour, minute: editTask.endTime.minute)
        : const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          editTask != null ? 'Edit Schedule Item' : 'Add Time Block',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppColors.darkTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            dropdownColor: AppColors.darkSurface,
                            style: const TextStyle(color: AppColors.darkTextPrimary),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPriority,
                            dropdownColor: AppColors.darkSurface,
                            style: const TextStyle(color: AppColors.darkTextPrimary),
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              labelStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _priorities
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedPriority = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.darkSurface,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (time != null) {
                                setSheetState(() => startTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded, color: Colors.grey, size: 18),
                            label: Text(
                              'Starts: ${startTime.format(context)}',
                              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.darkSurface,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (time != null) {
                                setSheetState(() => endTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded, color: Colors.grey, size: 18),
                            label: Text(
                              'Ends: ${endTime.format(context)}',
                              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a task title')),
                          );
                          return;
                        }

                        final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                        if (user == null) return;

                        final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                        final startDt = dateOnly.add(Duration(hours: startTime.hour, minutes: startTime.minute));
                        final endDt = dateOnly.add(Duration(hours: endTime.hour, minutes: endTime.minute));

                        if (endDt.isBefore(startDt)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('End time must be after start time')),
                          );
                          return;
                        }

                        final controller = ref.read(schedulerControllerProvider.notifier);

                        if (editTask != null) {
                          final updated = editTask.copyWith(
                            title: title,
                            startTime: startDt,
                            endTime: endDt,
                            category: selectedCategory,
                            priority: selectedPriority,
                          );
                          controller.editSchedule(updated);
                        } else {
                          final newSchedule = SchedulerModel(
                            id: '',
                            userId: user.uid,
                            title: title,
                            startTime: startDt,
                            endTime: endDt,
                            category: selectedCategory,
                            priority: selectedPriority,
                            completed: false,
                            createdAt: DateTime.now(),
                          );
                          controller.addSchedule(newSchedule);
                        }

                        Navigator.pop(context);
                      },
                      child: Text(
                        editTask != null ? 'Save Changes' : 'Schedule Block',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Construct 7-day calendar strip starting from today
    final calendarDays = List.generate(7, (idx) => today.add(Duration(days: idx)));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Block', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkTextPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${weekdayNames[_selectedDate.weekday - 1]}, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                    tooltip: 'Select Custom Date',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: AppColors.darkSurface,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // --- DATE SELECTOR STRIP ---
            Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: calendarDays.map((d) {
                  final isSelected = _isSameDay(d, _selectedDate);
                  final dayName = weekdayNames[d.weekday - 1];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = d;
                      });
                    },
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.darkTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // --- TIMELINE / WORKSPACE CONTENT ---
            Expanded(
              child: schedulesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (allSchedules) {
                  final dailyTasks = allSchedules
                      .where((task) => _isSameDay(task.startTime, _selectedDate))
                      .toList();

                  if (dailyTasks.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 52,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Your Schedule is Clear',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add focus blocks, gym sprints, or tasks to plan an optimized day.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showAddEditSheet(context),
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Schedule Time Block', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Responsive Timeline Column
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: dailyTasks.length,
                    itemBuilder: (context, index) {
                      final task = dailyTasks[index];
                      final catColor = _getCategoryColor(task.category);
                      final priorityColor = _getPriorityColor(task.priority);

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline axis on the left
                            Column(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: task.completed ? AppColors.secondary : catColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.darkBackground,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (task.completed ? AppColors.secondary : catColor)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: index == dailyTasks.length - 1
                                      ? const SizedBox(width: 2)
                                      : Container(
                                          width: 2,
                                          color: Colors.white12,
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Task Card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: task.completed
                                          ? AppColors.secondary.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.03),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onLongPress: () => _showAddEditSheet(context, editTask: task),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Completion check
                                            Checkbox(
                                              value: task.completed,
                                              activeColor: AppColors.secondary,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6)),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref
                                                      .read(schedulerControllerProvider.notifier)
                                                      .toggleCompletion(task, val);
                                                }
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: task.completed
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.darkTextPrimary,
                                                      decoration: task.completed
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time_rounded,
                                                        size: 13,
                                                        color: Colors.grey[500],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      // Category Pill
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: catColor.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          task.category,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            color: catColor,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Priority Pill
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: priorityColor.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '${task.priority} Priority',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            color: priorityColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Actions
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined,
                                                      color: Colors.grey, size: 18),
                                                  onPressed: () =>
                                                      _showAddEditSheet(context, editTask: task),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline,
                                                      color: AppColors.error, size: 18),
                                                  onPressed: () {
                                                    ref
                                                        .read(schedulerControllerProvider.notifier)
                                                        .deleteSchedule(task.id);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
