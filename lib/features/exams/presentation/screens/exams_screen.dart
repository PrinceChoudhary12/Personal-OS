// lib/features/exams/presentation/screens/exams_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/exam_providers.dart';
import '../../domain/models/exam_model.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exam Tracker',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.6),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Add Exam',
            onPressed: () => context.push('/exams/create'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming Exams'),
            Tab(text: 'Past Exams'),
          ],
        ),
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading exams: $err')),
        data: (exams) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final upcoming = exams.where((e) {
            final targetDate = DateTime(e.examDate.year, e.examDate.month, e.examDate.day);
            return targetDate.isAfter(today) || targetDate.isAtSameMomentAs(today);
          }).toList();

          final past = exams.where((e) {
            final targetDate = DateTime(e.examDate.year, e.examDate.month, e.examDate.day);
            return targetDate.isBefore(today);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildExamList(upcoming, isPast: false),
              _buildExamList(past, isPast: true),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/exams/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildExamList(List<ExamModel> list, {required bool isPast}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPast ? Icons.history_rounded : Icons.assignment_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPast ? 'No past exams found' : 'No upcoming exams scheduled',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isPast ? 'Your completed exams will appear here.' : 'Add your upcoming tests and stay prepared.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final exam = list[index];
        final remaining = exam.daysRemaining;
        final color = _getPriorityColor(exam.priority);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/exams/${exam.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                exam.priority,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exam.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (exam.syllabus.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            exam.syllabus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isPast) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          remaining == 0 ? 'TODAY' : '$remaining',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: remaining <= 2 ? Colors.redAccent : AppColors.primary,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          remaining == 1 ? 'Day Left' : 'Days Left',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
