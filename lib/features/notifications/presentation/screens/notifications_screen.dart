// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/reminder_model.dart';
import '../providers/notification_providers.dart';
import '../providers/reminder_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        return Colors.orange;
      case 'Focus':
        return Colors.red;
      case 'Activity':
        return Colors.blue;
      case 'AI':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Goal':
        return Icons.flag_rounded;
      case 'Focus':
        return Icons.timer_outlined;
      case 'Activity':
        return Icons.checklist_rtl_rounded;
      case 'AI':
        return Icons.psychology_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _showRemindersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const RemindersManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final controller = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark All as Read',
            onPressed: () => controller.markAllAsRead(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Alerts'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRemindersSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.alarm_rounded, color: Colors.white),
        label: const Text('Manage Reminders', style: TextStyle(color: Colors.white)),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading alerts: $err')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'System notifications and AI insights will appear here.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final unreadList = list.where((n) => !n.isRead).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(list, controller),
              _buildNotificationList(unreadList, controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> list, NotificationController controller) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No notifications in this filter.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80, left: 12, right: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final color = _getTypeColor(item.type);
        final icon = _getTypeIcon(item.type);

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) {
            controller.deleteNotification(item.id);
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: item.isRead 
                    ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.3),
                width: item.isRead ? 1 : 1.5,
              ),
            ),
            color: item.isRead 
                ? null 
                : color.withValues(alpha: 0.03),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: item.isRead ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              onTap: () {
                if (!item.isRead) {
                  controller.markAsRead(item.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── REMINDERS MANAGER SHEET ───
class RemindersManagerSheet extends ConsumerWidget {
  const RemindersManagerSheet({super.key});

  void _showAddEditReminderDialog(BuildContext context, WidgetRef ref, [ReminderModel? reminder]) {
    final titleController = TextEditingController(text: reminder?.title);
    final descController = TextEditingController(text: reminder?.description);
    String category = reminder?.type ?? 'General';
    String repeatType = reminder?.repeatType ?? 'None';
    TimeOfDay selectedTime = reminder != null 
        ? TimeOfDay(hour: reminder.triggerTime.hour, minute: reminder.triggerTime.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(reminder != null ? 'Edit Reminder' : 'Add Reminder'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Goal', child: Text('Goal')),
                      DropdownMenuItem(value: 'Focus', child: Text('Focus')),
                      DropdownMenuItem(value: 'Activity', child: Text('Activity')),
                      DropdownMenuItem(value: 'AI', child: Text('AI')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: repeatType,
                    decoration: const InputDecoration(labelText: 'Repeat'),
                    items: const [
                      DropdownMenuItem(value: 'None', child: Text('One-Time (None)')),
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => repeatType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) {
                        setStateDialog(() => selectedTime = time);
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text('Trigger Time: ${selectedTime.format(context)}'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                if (user == null) return;

                final now = DateTime.now();
                final trigger = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

                final newReminder = ReminderModel(
                  id: reminder?.id ?? '',
                  userId: user.uid,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  type: category,
                  triggerTime: trigger,
                  repeatType: repeatType,
                  isEnabled: reminder?.isEnabled ?? true,
                  createdAt: reminder?.createdAt ?? DateTime.now(),
                );

                final controller = ref.read(reminderControllerProvider.notifier);
                bool success;
                if (reminder != null) {
                  success = await controller.editReminder(newReminder);
                } else {
                  success = await controller.addReminder(newReminder);
                }

                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersStreamProvider);
    final controller = ref.read(reminderControllerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Custom Reminders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditReminderDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: remindersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No custom reminders set.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];

                      String triggerStr = "${item.triggerTime.hour.toString().padLeft(2, '0')}:${item.triggerTime.minute.toString().padLeft(2, '0')}";
                      if (item.repeatType != 'None') {
                        triggerStr += " (Repeats ${item.repeatType})";
                      } else {
                        triggerStr += " (One-Time)";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: item.isEnabled ? null : TextDecoration.lineThrough,
                              color: item.isEnabled ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item.description, style: const TextStyle(fontSize: 12)),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.alarm, size: 12, color: item.isEnabled ? AppColors.primary : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    triggerStr,
                                    style: TextStyle(
                                      fontSize: 11, 
                                      color: item.isEnabled ? AppColors.primary : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: item.isEnabled,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  controller.editReminder(item.copyWith(isEnabled: val));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showAddEditReminderDialog(context, ref, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => controller.removeReminder(item.id),
                              ),
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
    );
  }
}
