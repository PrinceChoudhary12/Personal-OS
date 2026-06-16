// lib/features/goals/presentation/screens/create_edit_goal_screen.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _targetHoursController;
  late TextEditingController _completedHoursController;

  String _selectedCategory = 'Study';
  String _status = 'Active';
  bool _isCompleted = false;
  DateTime? _originalCreatedAt;
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
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetHoursController = TextEditingController();
    _completedHoursController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetHoursController.dispose();
    _completedHoursController.dispose();
    super.dispose();
  }

  void _initializeWithGoal(GoalModel goal) {
    if (_initialized) return;
    _initialized = true;

    _titleController.text = goal.title;
    _descriptionController.text = goal.description;
    _targetHoursController.text = goal.targetHours.toString();
    _completedHoursController.text = goal.completedHours.toString();
    _selectedCategory = _categories.contains(goal.category) ? goal.category : 'Study';
    _status = goal.status;
    _isCompleted = goal.isCompleted;
    _originalCreatedAt = goal.createdAt;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final targetHours = double.tryParse(_targetHoursController.text.trim()) ?? 0.0;
    var completedHours = double.tryParse(_completedHoursController.text.trim()) ?? 0.0;

    if (widget.editGoalId == null) {
      completedHours = 0.0;
    }

    if (completedHours > targetHours) {
      completedHours = targetHours;
    }

    var isComp = _isCompleted || completedHours >= targetHours;
    var finalCompletedHours = isComp ? targetHours : completedHours;
    var finalProgress = targetHours > 0 
        ? (finalCompletedHours / targetHours * 100.0).clamp(0.0, 100.0) 
        : 0.0;
    
    // Automatically set status to completed if isComp is true
    var finalStatus = isComp ? 'Completed' : _status;
    if (finalStatus == 'Completed' && !isComp) {
      finalStatus = 'Active'; // revert if user manually unmarked complete and status was 'Completed'
    }

    final GoalModel newGoal = GoalModel(
      id: widget.editGoalId ?? '',
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      targetHours: targetHours,
      completedHours: finalCompletedHours,
      progressPercentage: finalProgress,
      isCompleted: isComp,
      status: finalStatus,
      createdAt: _originalCreatedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
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
                ? 'Goal created successfully! 🚀'
                : 'Goal updated successfully! 📝',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save goal. Please check your inputs.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(goalsControllerProvider);

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
                      // --- Goal Fields Card ---
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
                                enabled: !controllerState.isLoading,
                                decoration: const InputDecoration(
                                  labelText: 'Goal Title *',
                                  hintText: 'e.g. Master Clean Architecture',
                                  prefixIcon: Icon(Icons.title_rounded),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Please enter a goal title' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !controllerState.isLoading,
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

                      // --- Category & Parameters Card ---
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
                              // Category selection
                              DropdownButtonFormField<String>(
                                key: ValueKey(_selectedCategory),
                                initialValue: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                                onChanged: controllerState.isLoading
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedCategory = val;
                                          });
                                        }
                                      },
                              ),
                              const SizedBox(height: 16),

                              // Target Hours
                              TextFormField(
                                controller: _targetHoursController,
                                enabled: !controllerState.isLoading,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Target Hours *',
                                  hintText: 'e.g. 40.0',
                                  prefixIcon: Icon(Icons.hourglass_empty_rounded),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter target hours';
                                  }
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal <= 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                  return null;
                                },
                              ),

                              // Completed Hours (Only in Edit mode)
                              if (isEditing) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _completedHoursController,
                                  enabled: !controllerState.isLoading && !_isCompleted,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Completed Hours',
                                    hintText: 'e.g. 15.5',
                                    prefixIcon: Icon(Icons.hourglass_full_rounded),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter completed hours';
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal < 0) {
                                      return 'Please enter a valid non-negative number';
                                    }
                                    final targetVal = double.tryParse(_targetHoursController.text.trim()) ?? 0.0;
                                    if (numVal > targetVal) {
                                      return 'Completed hours cannot exceed target hours ($targetVal)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Status & Completion Checkbox (Only in Edit Mode) ---
                      if (isEditing)
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
                                CheckboxListTile(
                                  title: const Text('Mark Goal as Completed'),
                                  subtitle: const Text('Instantly sets progress to 100%'),
                                  value: _isCompleted,
                                  activeColor: AppColors.success,
                                  onChanged: controllerState.isLoading
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setState(() {
                                              _isCompleted = val;
                                              if (val) {
                                                _completedHoursController.text = _targetHoursController.text;
                                              }
                                            });
                                          }
                                        },
                                ),
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
                                      onChanged: controllerState.isLoading || _isCompleted
                                          ? null
                                          : (val) {
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
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // --- Save Button ---
                      ElevatedButton(
                        onPressed: controllerState.isLoading ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controllerState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
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
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
