// lib/features/student_hub/presentation/screens/student_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../scheduler/domain/models/scheduler_model.dart';
import '../../../scheduler/presentation/providers/scheduler_providers.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/placement_model.dart';
import '../../domain/models/subject_model.dart';
import '../providers/student_providers.dart';

class StudentHubScreen extends ConsumerStatefulWidget {
  const StudentHubScreen({super.key});

  @override
  ConsumerState<StudentHubScreen> createState() => _StudentHubScreenState();
}

class _StudentHubScreenState extends ConsumerState<StudentHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fallback dynamic semester calculations
  DateTime _getSemesterStart() {
    final now = DateTime.now();
    return now.month >= 7 ? DateTime(now.year, 7, 1) : DateTime(now.year, 1, 1);
  }

  DateTime _getSemesterEnd() {
    final now = DateTime.now();
    return now.month >= 7 ? DateTime(now.year, 12, 31) : DateTime(now.year, 6, 30);
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatRelativeDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) {
      return 'Overdue by ${difference.abs()} days';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $difference days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final attendanceAsync = ref.watch(attendanceStreamProvider);
    final assignmentsAsync = ref.watch(assignmentsStreamProvider);
    final placementsAsync = ref.watch(placementsStreamProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final subjects = subjectsAsync.valueOrNull ?? [];
    final attendanceLogs = attendanceAsync.valueOrNull ?? [];
    final assignments = assignmentsAsync.valueOrNull ?? [];
    final placements = placementsAsync.valueOrNull ?? [];
    final profile = profileAsync.valueOrNull;

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Hub',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.6),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: !isWide,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.book_outlined), text: 'Subjects'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Attendance'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Assignments'),
            Tab(icon: Icon(Icons.work_outline), text: 'Placements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, subjects, attendanceLogs, assignments, placements, profile),
          _buildSubjectsTab(context, subjects),
          _buildAttendanceTab(context, subjects, attendanceLogs),
          _buildAssignmentsTab(context, subjects, assignments),
          _buildPlacementsTab(context, placements),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. OVERVIEW TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    BuildContext context,
    List<SubjectModel> subjects,
    List<AttendanceModel> attendanceLogs,
    List<AssignmentModel> assignments,
    List<PlacementModel> placements,
    dynamic profile,
  ) {
    final now = DateTime.now();
    final semStart = _getSemesterStart();
    final semEnd = _getSemesterEnd();
    final totalDays = semEnd.difference(semStart).inDays;
    final elapsedDays = now.difference(semStart).inDays.clamp(0, totalDays);
    final semesterProgress = totalDays > 0 ? (elapsedDays / totalDays) : 0.0;

    // CGPA
    double totalCredits = 0.0;
    double totalPoints = 0.0;
    for (final s in subjects) {
      if (s.isCompleted && s.gradePoint != null) {
        totalCredits += s.credits;
        totalPoints += (s.credits * s.gradePoint!);
      }
    }
    final cgpa = totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;

    // Semester GPA
    final currentSem = profile?.semester ?? 1;
    double semCredits = 0.0;
    double semPoints = 0.0;
    for (final s in subjects) {
      if (s.semester == currentSem && s.isCompleted && s.gradePoint != null) {
        semCredits += s.credits;
        semPoints += (s.credits * s.gradePoint!);
      }
    }
    final semGpa = semCredits > 0 ? (semPoints / semCredits) : 0.0;

    // Attendance Warnings
    final warnings = <String>[];
    for (final s in subjects) {
      final logs = attendanceLogs.where((l) => l.subjectId == s.id).toList();
      if (logs.isNotEmpty) {
        final presents = logs.where((l) => l.status == 'present').length;
        final absents = logs.where((l) => l.status == 'absent').length;
        final total = presents + absents;
        if (total > 0) {
          final rate = (presents / total) * 100.0;
          if (rate < 75.0) {
            warnings.add('${s.name} (${s.code}): ${rate.toStringAsFixed(1)}%');
          }
        }
      }
    }

    final pendingAssignments = assignments.where((a) => a.status == 'Pending').toList();
    final activePlacements = placements.where((p) => p.status == 'Interviewing' || p.status == 'Assessment').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'CUMULATIVE GPA',
                  value: cgpa > 0 ? cgpa.toStringAsFixed(2) : 'N/A',
                  subtitle: '$totalCredits Total Credits',
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'SEMESTER $currentSem GPA',
                  value: semGpa > 0 ? semGpa.toStringAsFixed(2) : 'N/A',
                  subtitle: '$semCredits Active Credits',
                  icon: Icons.history_edu_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semester Progress',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semester $currentSem (${_formatDate(semStart)} to ${_formatDate(semEnd)})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        '${(semesterProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: semesterProgress,
                      minHeight: 12,
                      backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$elapsedDays of $totalDays days elapsed this semester.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Low Attendance Alert',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right_rounded, color: AppColors.error, size: 20),
                            Text(
                              w,
                              style: const TextStyle(fontSize: 13, color: AppColors.error),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSummaryListCard(
                  context,
                  title: 'Pending Assignments',
                  icon: Icons.assignment_late_outlined,
                  items: pendingAssignments.map((a) => a.title).toList(),
                  subtitles: pendingAssignments.map((a) => _formatRelativeDate(a.dueDate)).toList(),
                  emptyMessage: 'No pending assignments! Nice job.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryListCard(
                  context,
                  title: 'Placement Pipeline',
                  icon: Icons.business_center_outlined,
                  items: activePlacements.map((p) => '${p.role} at ${p.company}').toList(),
                  subtitles: activePlacements.map((p) => p.status).toList(),
                  emptyMessage: 'No interviews lined up right now.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryListCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    required List<String> subtitles,
    required String emptyMessage,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length.clamp(0, 4),
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitles[i],
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SUBJECTS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSubjectsTab(BuildContext context, List<SubjectModel> subjects) {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No subjects tracked yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddEditSubjectDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSubjectDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final s = subjects[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                child: Text(s.code.isNotEmpty ? s.code.substring(0, 1).toUpperCase() : '?'),
              ),
              title: Text(
                '${s.name} (${s.code})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                'Semester ${s.semester} • ${s.credits} Credits ${s.isCompleted ? '• Completed' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.isCompleted && s.grade != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Grade: ${s.grade}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showAddEditSubjectDialog(context, s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => ref.read(studentHubControllerProvider.notifier).deleteSubject(s.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEditSubjectDialog(BuildContext context, [SubjectModel? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final codeController = TextEditingController(text: existing?.code ?? '');
    final creditsController = TextEditingController(text: existing?.credits.toString() ?? '4');
    final gradeController = TextEditingController(text: existing?.grade ?? '');
    final gradePointController = TextEditingController(text: existing?.gradePoint?.toString() ?? '');
    final semesterController = TextEditingController(text: existing?.semester.toString() ?? '1');
    bool isCompleted = existing?.isCompleted ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Subject' : 'Edit Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name')),
                    TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Course Code (e.g. CS101)')),
                    TextField(controller: creditsController, decoration: const InputDecoration(labelText: 'Credits'), keyboardType: TextInputType.number),
                    TextField(controller: semesterController, decoration: const InputDecoration(labelText: 'Semester'), keyboardType: TextInputType.number),
                    CheckboxListTile(
                      title: const Text('Is Completed?'),
                      value: isCompleted,
                      onChanged: (val) => setState(() => isCompleted = val ?? false),
                    ),
                    if (isCompleted) ...[
                      TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'Grade String (e.g. A+, B)')),
                      TextField(controller: gradePointController, decoration: const InputDecoration(labelText: 'Grade Point (e.g. 9.0 or 4.0)'), keyboardType: TextInputType.number),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                    if (user == null) return;

                    final sub = SubjectModel(
                      id: existing?.id ?? '',
                      userId: user.uid,
                      name: nameController.text,
                      code: codeController.text,
                      credits: double.tryParse(creditsController.text) ?? 4.0,
                      semester: int.tryParse(semesterController.text) ?? 1,
                      isCompleted: isCompleted,
                      grade: isCompleted ? gradeController.text : null,
                      gradePoint: isCompleted ? double.tryParse(gradePointController.text) : null,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing == null) {
                      await ref.read(studentHubControllerProvider.notifier).addSubject(sub);
                    } else {
                      await ref.read(studentHubControllerProvider.notifier).editSubject(sub);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. ATTENDANCE TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAttendanceTab(
    BuildContext context,
    List<SubjectModel> subjects,
    List<AttendanceModel> attendanceLogs,
  ) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text('Create subjects first to track attendance.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final s = subjects[index];
        final logs = attendanceLogs.where((log) => log.subjectId == s.id).toList();

        final presents = logs.where((log) => log.status == 'present').length;
        final absents = logs.where((log) => log.status == 'absent').length;
        final totalClasses = presents + absents; // Excused doesn't harm attendance percentage

        final rate = totalClasses > 0 ? (presents / totalClasses) * 100.0 : 100.0;
        final isWarning = rate < 75.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(s.code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isWarning ? AppColors.error : AppColors.secondary,
                          ),
                        ),
                        Text(
                          '$presents / $totalClasses attended',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalClasses > 0 ? (presents / totalClasses) : 1.0,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    color: isWarning ? AppColors.error : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _markAttendanceFast(s.id, 'present'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _markAttendanceFast(s.id, 'absent'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Absent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showAttendanceHistoryModal(context, s, logs),
                      child: const Text('Log History'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAttendanceFast(String subjectId, String status) async {
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;
    final model = AttendanceModel(
      id: '',
      userId: user.uid,
      subjectId: subjectId,
      date: DateTime.now(),
      status: status,
    );
    await ref.read(studentHubControllerProvider.notifier).logAttendance(model);
  }

  void _showAttendanceHistoryModal(BuildContext context, SubjectModel subject, List<AttendanceModel> logs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attendance Logs: ${subject.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _logAttendanceCustomDate(context, subject.id),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: logs.isEmpty
                        ? const Center(child: Text('No attendance records logged.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              final color = log.status == 'present'
                                  ? AppColors.secondary
                                  : log.status == 'absent'
                                      ? AppColors.error
                                      : AppColors.accent;

                              return ListTile(
                                leading: Icon(Icons.circle, color: color, size: 14),
                                title: Text(log.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                                subtitle: Text(_formatDate(log.date), style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  onPressed: () async {
                                    await ref.read(studentHubControllerProvider.notifier).deleteAttendance(log.id);
                                    setState(() {
                                      logs.removeWhere((item) => item.id == log.id);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logAttendanceCustomDate(BuildContext context, String subjectId) async {
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Mark Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Present'),
                  leading: const Icon(Icons.check, color: AppColors.secondary),
                  onTap: () async {
                    final log = AttendanceModel(
                      id: '',
                      userId: user.uid,
                      subjectId: subjectId,
                      date: pickedDate,
                      status: 'present',
                    );
                    await ref.read(studentHubControllerProvider.notifier).logAttendance(log);
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Absent'),
                  leading: const Icon(Icons.close, color: AppColors.error),
                  onTap: () async {
                    final log = AttendanceModel(
                      id: '',
                      userId: user.uid,
                      subjectId: subjectId,
                      date: pickedDate,
                      status: 'absent',
                    );
                    await ref.read(studentHubControllerProvider.notifier).logAttendance(log);
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Excused'),
                  leading: const Icon(Icons.info_outline, color: AppColors.accent),
                  onTap: () async {
                    final log = AttendanceModel(
                      id: '',
                      userId: user.uid,
                      subjectId: subjectId,
                      date: pickedDate,
                      status: 'excused',
                    );
                    await ref.read(studentHubControllerProvider.notifier).logAttendance(log);
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. ASSIGNMENTS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAssignmentsTab(
    BuildContext context,
    List<SubjectModel> subjects,
    List<AssignmentModel> assignments,
  ) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text('Create subjects first to track assignments.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAssignmentDialog(context, subjects),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Submitted'),
                Tab(text: 'Graded'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAssignmentList(context, subjects, assignments.where((a) => a.status == 'Pending').toList()),
                  _buildAssignmentList(context, subjects, assignments.where((a) => a.status == 'Submitted').toList()),
                  _buildAssignmentList(context, subjects, assignments.where((a) => a.status == 'Graded').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentList(
    BuildContext context,
    List<SubjectModel> subjects,
    List<AssignmentModel> list,
  ) {
    if (list.isEmpty) {
      return const Center(child: Text('No assignments found here.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final a = list[index];
        final sub = subjects.firstWhere((item) => item.id == a.subjectId,
            orElse: () => SubjectModel(
                  id: '',
                  userId: '',
                  name: 'Unknown Subject',
                  code: 'SUB',
                  credits: 0,
                  semester: 1,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                ));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${sub.name} (${sub.code})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (a.status == 'Graded' && a.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Score: ${a.score}/${a.maxScore ?? 100}',
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(a.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _formatRelativeDate(a.dueDate),
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (a.status == 'Pending')
                      ElevatedButton.icon(
                        onPressed: () => _scheduleStudyBlock(context, a),
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text('Schedule Block'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showAddEditAssignmentDialog(context, subjects, a),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => ref.read(studentHubControllerProvider.notifier).deleteAssignment(a.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scheduleStudyBlock(BuildContext context, AssignmentModel assignment) async {
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    final now = DateTime.now();
    final schedule = SchedulerModel(
      id: '',
      userId: user.uid,
      title: 'Study: ${assignment.title}',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      category: 'Study',
      priority: 'High',
      completed: false,
      createdAt: now,
    );

    try {
      await ref.read(schedulerControllerProvider.notifier).addSchedule(schedule);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study block scheduled in Smart Scheduler!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule block: $e')),
        );
      }
    }
  }

  void _showAddEditAssignmentDialog(BuildContext context, List<SubjectModel> subjects, [AssignmentModel? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final scoreController = TextEditingController(text: existing?.score?.toString() ?? '');
    final maxScoreController = TextEditingController(text: existing?.maxScore?.toString() ?? '100');
    final gradeController = TextEditingController(text: existing?.grade ?? '');
    String selectedSubjectId = existing?.subjectId ?? (subjects.isNotEmpty ? subjects.first.id : '');
    String selectedStatus = existing?.status ?? 'Pending';
    DateTime selectedDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Assignment' : 'Edit Assignment', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map((sub) {
                        return DropdownMenuItem(value: sub.id, child: Text('${sub.name} (${sub.code})'));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedSubjectId = val ?? ''),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'Graded', child: Text('Graded')),
                      ],
                      onChanged: (val) => setState(() => selectedStatus = val ?? 'Pending'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due Date: ${_formatDate(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    if (selectedStatus == 'Graded') ...[
                      TextField(controller: scoreController, decoration: const InputDecoration(labelText: 'Score Obtained'), keyboardType: TextInputType.number),
                      TextField(controller: maxScoreController, decoration: const InputDecoration(labelText: 'Maximum Score'), keyboardType: TextInputType.number),
                      TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'Grade (e.g. A, B)')),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                    if (user == null) return;

                    final model = AssignmentModel(
                      id: existing?.id ?? '',
                      userId: user.uid,
                      subjectId: selectedSubjectId,
                      title: titleController.text,
                      description: descController.text,
                      dueDate: selectedDate,
                      status: selectedStatus,
                      score: selectedStatus == 'Graded' ? double.tryParse(scoreController.text) : null,
                      maxScore: selectedStatus == 'Graded' ? double.tryParse(maxScoreController.text) : null,
                      grade: selectedStatus == 'Graded' ? gradeController.text : null,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing == null) {
                      await ref.read(studentHubControllerProvider.notifier).addAssignment(model);
                    } else {
                      await ref.read(studentHubControllerProvider.notifier).editAssignment(model);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. PLACEMENTS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPlacementsTab(BuildContext context, List<PlacementModel> placements) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPlacementDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Wishlist'),
                Tab(text: 'Applied'),
                Tab(text: 'Interviewing'),
                Tab(text: 'Offered'),
                Tab(text: 'Rejected'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlacementList(context, placements.where((p) => p.status == 'Wishlist').toList()),
                  _buildPlacementList(context, placements.where((p) => p.status == 'Applied').toList()),
                  _buildPlacementList(context, placements.where((p) => p.status == 'Interviewing' || p.status == 'Assessment').toList()),
                  _buildPlacementList(context, placements.where((p) => p.status == 'Offered').toList()),
                  _buildPlacementList(context, placements.where((p) => p.status == 'Rejected').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementList(BuildContext context, List<PlacementModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No applications here.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(p.role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (p.salary != null)
                      Text(
                        p.salary!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (p.location != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(p.location!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                if (p.notes != null && p.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
                if (p.interviewDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Interview Scheduled: ${_formatDate(p.interviewDate!)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showAddEditPlacementDialog(context, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => ref.read(studentHubControllerProvider.notifier).deletePlacement(p.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEditPlacementDialog(BuildContext context, [PlacementModel? existing]) {
    final companyController = TextEditingController(text: existing?.company ?? '');
    final roleController = TextEditingController(text: existing?.role ?? '');
    final salaryController = TextEditingController(text: existing?.salary ?? '');
    final locationController = TextEditingController(text: existing?.location ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedStatus = existing?.status ?? 'Wishlist';
    DateTime? appliedDate = existing?.appliedDate;
    DateTime? interviewDate = existing?.interviewDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Application' : 'Edit Application', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
                    TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role')),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'Wishlist', child: Text('Wishlist')),
                        DropdownMenuItem(value: 'Applied', child: Text('Applied')),
                        DropdownMenuItem(value: 'Assessment', child: Text('Assessment')),
                        DropdownMenuItem(value: 'Interviewing', child: Text('Interviewing')),
                        DropdownMenuItem(value: 'Offered', child: Text('Offered')),
                        DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) => setState(() => selectedStatus = val ?? 'Wishlist'),
                    ),
                    TextField(controller: salaryController, decoration: const InputDecoration(labelText: 'Package / Salary')),
                    TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                    TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Prep Notes')),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(appliedDate == null ? 'Set Applied Date' : 'Applied: ${_formatDate(appliedDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => appliedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(interviewDate == null ? 'Set Interview Date' : 'Interview: ${_formatDate(interviewDate!)}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => interviewDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
                    if (user == null) return;

                    final model = PlacementModel(
                      id: existing?.id ?? '',
                      userId: user.uid,
                      company: companyController.text,
                      role: roleController.text,
                      status: selectedStatus,
                      salary: salaryController.text.isNotEmpty ? salaryController.text : null,
                      location: locationController.text.isNotEmpty ? locationController.text : null,
                      notes: notesController.text.isNotEmpty ? notesController.text : null,
                      appliedDate: appliedDate,
                      interviewDate: interviewDate,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (existing == null) {
                      await ref.read(studentHubControllerProvider.notifier).addPlacement(model);
                    } else {
                      await ref.read(studentHubControllerProvider.notifier).editPlacement(model);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
