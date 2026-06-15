// lib/features/goals/presentation/screens/create_edit_goal_screen.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/goal_model.dart';
import '../providers/goals_controllers.dart';
import '../providers/goals_providers.dart';

class CreateEditGoalScreen extends ConsumerStatefulWidget {
  final String? editGoalId;

  const CreateEditGoalScreen({
    this.editGoalId,
    super.key,
  });

  @override
  ConsumerState<CreateEditGoalScreen> createState() => _CreateEditGoalScreenState();
}

class _CreateEditGoalScreenState extends ConsumerState<CreateEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _status;
  
  // Custom structure to hold milestone drafts
  final List<_MilestoneDraft> _milestones = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now().add(const Duration(days: 30));
    _status = 'Active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final m in _milestones) {
      m.controller.dispose();
    }
    super.dispose();
  }

  void _initializeWithGoal(GoalModel goal) {
    if (_initialized) return;
    _initialized = true;
    
    _titleController.text = goal.title;
    _descriptionController.text = goal.description;
    _selectedDate = goal.targetDate;
    _status = goal.status;

    _milestones.clear();
    for (final milestone in goal.milestones) {
      _milestones.add(
        _MilestoneDraft(
          id: milestone.id,
          controller: TextEditingController(text: milestone.title),
          isCompleted: milestone.isCompleted,
        ),
      );
    }
  }

  void _addMilestoneRow() {
    setState(() {
      _milestones.add(
        _MilestoneDraft(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          controller: TextEditingController(),
          isCompleted: false,
        ),
      );
    });
  }

  void _removeMilestoneRow(int index) {
    setState(() {
      final removed = _milestones.removeAt(index);
      removed.controller.dispose();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final parsedMilestones = _milestones
        .map((m) => MilestoneModel(
              id: m.id,
              title: m.controller.text.trim(),
              isCompleted: m.isCompleted,
            ))
        .where((m) => m.title.isNotEmpty)
        .toList();

    // Calculate progress percentage
    final completedCount = parsedMilestones.where((m) => m.isCompleted).length;
    final totalCount = parsedMilestones.length;
    final double progress = totalCount > 0 
        ? (completedCount / totalCount * 100.0) 
        : 0.0;

    final GoalModel newGoal = GoalModel(
      id: widget.editGoalId ?? '',
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      targetDate: _selectedDate,
      progressPercentage: progress,
      milestones: parsedMilestones,
      status: progress >= 100.0 ? 'Completed' : _status,
      createdAt: DateTime.now(),
    );

    bool success;
    if (widget.editGoalId == null) {
      success = await ref.read(goalsControllerProvider.notifier).createGoal(newGoal);
    } else {
      success = await ref.read(goalsControllerProvider.notifier).updateGoal(newGoal);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editGoalId == null
                ? 'Goal created successfully!'
                : 'Goal updated successfully!',
          ),
        ),
      );
      context.pop();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(goalsControllerProvider);

    // If editing, find existing goal details
    if (widget.editGoalId != null) {
      final goalsList = ref.watch(goalsStreamProvider).valueOrNull ?? [];
      final goal = goalsList.firstWhereOrNull((g) => g.id == widget.editGoalId);
      if (goal != null) {
        _initializeWithGoal(goal);
      }
    }

    final isEditing = widget.editGoalId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Set New Goal'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Goal Card Container ---
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Goal Title',
                                  hintText: 'e.g. Master Clean Architecture',
                                  prefixIcon: Icon(Icons.title_rounded),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Please enter a goal title' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Explain the purpose or motivation behind this goal...',
                                  prefixIcon: Icon(Icons.description_outlined),
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Goal Configurations ---
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Target Date Selection
                              Row(
                                children: [
                                  const Icon(Icons.event_rounded, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Target Completion Date',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(_selectedDate),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _selectDate(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                    ),
                                    child: const Text('Pick Date'),
                                  ),
                                ],
                              ),

                              // Status Selector (only when editing)
                              if (isEditing) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.checklist_rtl_rounded, color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Goal Status',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: _status,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _status = val;
                                          });
                                        }
                                      },
                                      items: ['Active', 'Completed', 'Abandoned'].map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Milestones Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Milestones & Steps',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton.icon(
                            onPressed: _addMilestoneRow,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Add Step'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_milestones.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No milestones added. Add smaller key steps to track your progress step-by-step.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _milestones.length,
                          itemBuilder: (context, idx) {
                            final milestone = _milestones[idx];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: milestone.isCompleted,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            milestone.isCompleted = val;
                                          });
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: milestone.controller,
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. Finish reading Chapter 1',
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        ),
                                        validator: (val) =>
                                            (val == null || val.trim().isEmpty) ? 'Enter a step description' : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                                      onPressed: () => _removeMilestoneRow(idx),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 32),

                      // --- Submit Buttons ---
                      ElevatedButton(
                        onPressed: _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Goal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (controllerState.isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneDraft {
  final String id;
  final TextEditingController controller;
  bool isCompleted;

  _MilestoneDraft({
    required this.id,
    required this.controller,
    required this.isCompleted,
  });
}
