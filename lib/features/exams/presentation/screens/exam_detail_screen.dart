// lib/features/exams/presentation/screens/exam_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/exam_providers.dart';
import '../../domain/models/exam_model.dart';
import '../../domain/models/revision_plan_model.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamDetailScreen({required this.examId, super.key});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  final _topicController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  void _addTopic(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Revision Topic'),
          content: TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              hintText: 'e.g. Chapter 4: Integration by Parts',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _topicController.clear();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = _topicController.text.trim();
                if (text.isEmpty) return;
                
                final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                if (user == null) return;

                final plan = RevisionPlanModel(
                  id: '',
                  examId: widget.examId,
                  userId: user.uid,
                  topicName: text,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await ref.read(examControllerProvider.notifier).addRevisionPlan(plan);
                
                _topicController.clear();
                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExamConfirm(ExamModel exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete ${exam.subject}? All related revision topics will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(examControllerProvider.notifier).deleteExam(exam.id, exam.subject);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examsStreamProvider).valueOrNull ?? [];
    final exam = exams.where((e) => e.id == widget.examId).firstOrNull;

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Exam not found.')),
      );
    }

    final revisionPlansAsync = ref.watch(revisionPlansStreamProvider(widget.examId));
    final color = _getPriorityColor(exam.priority);
    final remaining = exam.daysRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Exam',
            onPressed: () => context.push('/exams/edit/${exam.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Exam',
            onPressed: () => _deleteExamConfirm(exam),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Segment Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exam.priority,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Date: ${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              exam.subject,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            if (exam.syllabus.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                exam.syllabus,
                                style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            remaining == 0 ? 'TODAY' : '$remaining',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: remaining <= 2 ? Colors.redAccent : AppColors.primary,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Text(
                            remaining == 1 ? 'Day Left' : 'Days Left',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Targets card
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Target',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${exam.dailyStudyGoalMinutes} mins',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Target',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${exam.weeklyStudyGoalMinutes} mins',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Revision Planner Segment Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Revision Planner',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                    TextButton.icon(
                      onPressed: () => _addTopic(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Topic', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),

                // Revision plans content
                revisionPlansAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Error loading plans: $err'),
                  data: (plansList) {
                    if (plansList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                'No revision topics added yet.',
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _addTopic(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Create Study Plan'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final completedCount = plansList.where((p) => p.isCompleted).length;
                    final totalCount = plansList.length;
                    final double progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Revision progress card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedCount of $totalCount topics revised',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}% Complete',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Checkbox topics list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plansList.length,
                          itemBuilder: (context, idx) {
                            final topic = plansList[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: topic.isCompleted,
                                activeColor: AppColors.primary,
                                onChanged: (_) async {
                                  await ref
                                      .read(examControllerProvider.notifier)
                                      .toggleRevisionPlanCompletion(topic);
                                },
                              ),
                              title: Text(
                                topic.topicName,
                                style: TextStyle(
                                  decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                                  color: topic.isCompleted ? Colors.grey : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                onPressed: () async {
                                  await ref
                                      .read(examControllerProvider.notifier)
                                      .deleteRevisionPlan(topic.id);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
