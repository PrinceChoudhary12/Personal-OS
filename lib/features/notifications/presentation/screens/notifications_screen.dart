// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/reminder_model.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = ['General', 'Goal', 'Streak', 'Focus', 'AI'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Goal':
        return Colors.orangeAccent;
      case 'Streak':
        return Colors.redAccent;
      case 'Focus':
        return Colors.indigoAccent;
      case 'AI':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Goal':
        return Icons.flag_rounded;
      case 'Streak':
        return Icons.local_fire_department_rounded;
      case 'Focus':
        return Icons.timer_outlined;
      case 'AI':
        return Icons.psychology_rounded;
      default:
        return Icons.alarm_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, $hour:$minute $ampm';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
      return 'Tomorrow, $hour:$minute $ampm';
    }
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$minute $ampm';
  }

  void _showAddEditReminderDialog(BuildContext context, {ReminderModel? editReminder}) {
    final titleController = TextEditingController(text: editReminder?.title ?? '');
    final descController = TextEditingController(text: editReminder?.description ?? '');
    String selectedType = editReminder?.type ?? 'General';
    
    DateTime selectedTime = editReminder?.reminderTime ?? DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            editReminder != null ? 'Edit Reminder' : 'Create Reminder',
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
                    labelText: 'Title *',
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
                  initialValue: selectedType,
                  dropdownColor: AppColors.darkSurface,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;

                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (time == null) return;

                    setStateDialog(() {
                      selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  },
                  icon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  label: Text(
                    'Time: ${_formatDateTime(selectedTime)}',
                    style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12),
                  ),
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

                final controller = ref.read(notificationControllerProvider.notifier);

                if (editReminder != null) {
                  final updated = editReminder.copyWith(
                    title: title,
                    description: descController.text.trim(),
                    type: selectedType,
                    reminderTime: selectedTime,
                  );
                  controller.editReminder(updated);
                } else {
                  final newReminder = ReminderModel(
                    id: '',
                    userId: user.uid,
                    title: title,
                    description: descController.text.trim(),
                    reminderTime: selectedTime,
                    type: selectedType,
                    completed: false,
                    createdAt: DateTime.now(),
                  );
                  controller.addReminder(newReminder);
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final controller = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Notification Center', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming Reminders'),
            Tab(text: 'Completed Alerts'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditReminderDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (list) {
          final upcoming = list.where((item) => !item.completed).toList();
          final completed = list.where((item) => item.completed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(upcoming, controller, 'No upcoming reminders scheduled.'),
              _buildList(completed, controller, 'No completed reminders in history.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<ReminderModel> items, NotificationController controller, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                style: const TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final reminder = items[index];
        final color = _getTypeColor(reminder.type);
        final icon = _getTypeIcon(reminder.type);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          color: AppColors.darkSurface,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              value: reminder.completed,
              activeColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                if (val != null) {
                  controller.toggleCompletion(reminder, val);
                }
              },
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: reminder.completed ? TextDecoration.lineThrough : null,
                      color: reminder.completed ? AppColors.darkTextSecondary : AppColors.darkTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reminder.type,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reminder.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.description,
                    style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(icon, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(reminder.reminderTime),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
                  onPressed: () => _showAddEditReminderDialog(context, editReminder: reminder),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  onPressed: () => controller.deleteReminder(reminder.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
