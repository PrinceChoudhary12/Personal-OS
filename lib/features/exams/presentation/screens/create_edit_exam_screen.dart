// lib/features/exams/presentation/screens/create_edit_exam_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/exam_providers.dart';
import '../../domain/models/exam_model.dart';

class CreateEditExamScreen extends ConsumerStatefulWidget {
  final String? editExamId;

  const CreateEditExamScreen({this.editExamId, super.key});

  @override
  ConsumerState<CreateEditExamScreen> createState() => _CreateEditExamScreenState();
}

class _CreateEditExamScreenState extends ConsumerState<CreateEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _syllabusController = TextEditingController();
  final _dailyGoalController = TextEditingController(text: '60');
  final _weeklyGoalController = TextEditingController(text: '300');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedPriority = 'Medium';
  bool _isInit = false;
  ExamModel? _existingExam;

  @override
  void dispose() {
    _subjectController.dispose();
    _syllabusController.dispose();
    _dailyGoalController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    final exam = ExamModel(
      id: widget.editExamId ?? '',
      userId: user.uid,
      subject: _subjectController.text.trim(),
      examDate: _selectedDate,
      priority: _selectedPriority,
      syllabus: _syllabusController.text.trim(),
      dailyStudyGoalMinutes: int.tryParse(_dailyGoalController.text) ?? 60,
      weeklyStudyGoalMinutes: int.tryParse(_weeklyGoalController.text) ?? 300,
      createdAt: _existingExam?.createdAt ?? DateTime.now(),
    );

    if (widget.editExamId != null) {
      await ref.read(examControllerProvider.notifier).editExam(exam);
    } else {
      await ref.read(examControllerProvider.notifier).addExam(exam);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examsStreamProvider).valueOrNull ?? [];
    
    if (widget.editExamId != null && !_isInit) {
      _existingExam = exams.where((e) => e.id == widget.editExamId).firstOrNull;
      if (_existingExam != null) {
        _subjectController.text = _existingExam!.subject;
        _syllabusController.text = _existingExam!.syllabus;
        _dailyGoalController.text = _existingExam!.dailyStudyGoalMinutes.toString();
        _weeklyGoalController.text = _existingExam!.weeklyStudyGoalMinutes.toString();
        _selectedDate = _existingExam!.examDate;
        _selectedPriority = _existingExam!.priority;
      }
      _isInit = true;
    }

    final isSaving = ref.watch(examControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editExamId != null ? 'Edit Exam' : 'Schedule Exam'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subject Name
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject / Course Name',
                      hintText: 'e.g. Advanced Calculus',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                  ),
                  const SizedBox(height: 20),

                  // Exam Date Picker Row
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Exam Date',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Priority Selector dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority Level',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.warning_amber_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High Priority')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium Priority')),
                      DropdownMenuItem(value: 'Low', child: Text('Low Priority')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPriority = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Syllabus Syllabus Input
                  TextFormField(
                    controller: _syllabusController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Syllabus / Focus Areas',
                      hintText: 'Describe key chapters, scope of prep, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Study Targets Segment Header
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Configure Study Targets',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dailyGoalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Daily Goal (mins)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter minutes';
                            if (int.tryParse(val) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weeklyGoalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weekly Goal (mins)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter minutes';
                            if (int.tryParse(val) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  FilledButton(
                    onPressed: isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.editExamId != null ? 'Update Exam Details' : 'Add to Exam Schedule',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
