// lib/features/activities/presentation/screens/create_edit_activity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/activity_model.dart';
import '../providers/activity_providers.dart';

class CreateEditActivityScreen extends ConsumerStatefulWidget {
  final String? editActivityId;

  const CreateEditActivityScreen({
    this.editActivityId,
    super.key,
  });

  @override
  ConsumerState<CreateEditActivityScreen> createState() =>
      _CreateEditActivityScreenState();
}

class _CreateEditActivityScreenState
    extends ConsumerState<CreateEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

  String _selectedCategory = 'Study';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)));

  bool _initialized = false;

  final List<String> _categories = const [
    'Study',
    'Coding',
    'Reading',
    'Gym',
    'Sleep',
    'Meeting',
    'Project',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initializeValues(ActivityModel activity) {
    if (_initialized) return;
    _titleCtrl.text = activity.title;
    _notesCtrl.text = activity.notes;
    _selectedCategory = _categories.contains(activity.category)
        ? activity.category
        : 'Study';
    _selectedDate = activity.startTime;
    _startTime = TimeOfDay.fromDateTime(activity.startTime);
    _endTime = TimeOfDay.fromDateTime(activity.endTime);
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _submit(String userId) {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // If end time is technically before start time, assume it overflows to the next day
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final durationMin = endDateTime.difference(startDateTime).inMinutes;

    if (durationMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final activity = ActivityModel(
      id: widget.editActivityId ?? '',
      userId: userId,
      title: _titleCtrl.text.trim(),
      category: _selectedCategory,
      notes: _notesCtrl.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      duration: durationMin,
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(activityControllerProvider.notifier);
    if (widget.editActivityId == null) {
      notifier.addActivity(activity);
    } else {
      notifier.editActivity(activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    final saveState = ref.watch(activityControllerProvider);

    // Redirect or show success
    ref.listen<AsyncValue>(activityControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (prev is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.editActivityId == null
                    ? 'Activity logged successfully! 🚀'
                    : 'Activity updated successfully! 📝'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/activities');
          }
        },
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save activity: $err'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Unauthenticated user.')),
      );
    }

    // Load initial activity details if editing
    if (widget.editActivityId != null) {
      final listAsync = ref.watch(activitiesStreamProvider);
      listAsync.whenData((list) {
        final match = list.firstWhereOrNull((a) => a.id == widget.editActivityId);
        if (match != null) {
          _initializeValues(match);
        }
      });
    }

    final isNew = widget.editActivityId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Log Activity' : 'Edit Activity'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        enabled: !saveState.isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Activity Title *',
                          prefixIcon: Icon(Icons.bookmark_border_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter an activity title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((cat) => DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: saveState.isLoading
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notesCtrl,
                        enabled: !saveState.isLoading,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes & Log Details',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Date & Time Pickers ---
                      const Text(
                        'Time Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Divider(height: 12),

                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        tileColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Date'),
                        subtitle: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        leading: const Icon(Icons.calendar_today_rounded),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: saveState.isLoading ? null : _pickDate,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              tileColor: Theme.of(context).colorScheme.surface,
                              title: const Text('Start Time'),
                              subtitle: Text(_startTime.format(context)),
                              leading: const Icon(Icons.access_time_rounded),
                              trailing: const Icon(Icons.arrow_drop_down),
                              onTap: saveState.isLoading ? null : _pickStartTime,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              tileColor: Theme.of(context).colorScheme.surface,
                              title: const Text('End Time'),
                              subtitle: Text(_endTime.format(context)),
                              leading: const Icon(Icons.access_time_filled),
                              trailing: const Icon(Icons.arrow_drop_down),
                              onTap: saveState.isLoading ? null : _pickEndTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // --- Submit & Cancel Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saveState.isLoading
                                  ? null
                                  : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: saveState.isLoading
                                  ? null
                                  : () => _submit(user.uid),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isNew ? 'Log Activity' : 'Save Changes',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (saveState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
