// lib/features/scheduler/data/repositories/firestore_schedule_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/schedule_model.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../ai_coach/domain/models/ai_insight_model.dart';

class FirestoreScheduleRepository implements ScheduleRepository {
  final FirebaseFirestore _firestore;

  FirestoreScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('schedules');

  String _getDocId(String userId, DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${userId}_$y-$m-$d';
  }

  @override
  Future<ScheduleModel?> getSchedule(String userId, DateTime date) async {
    try {
      final docId = _getDocId(userId, date);
      final doc = await _collection.doc(docId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ScheduleModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ScheduleModel?> streamSchedule(String userId, DateTime date) {
    final docId = _getDocId(userId, date);
    return _collection.doc(docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ScheduleModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> saveSchedule(ScheduleModel schedule) async {
    try {
      await _collection.doc(schedule.id).set(schedule.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateTaskCompletion(
    String userId,
    DateTime date,
    String taskId,
    bool completed,
  ) async {
    try {
      final schedule = await getSchedule(userId, date);
      if (schedule == null) {
        return;
      }

      final updatedTasks = schedule.scheduledTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(completed: completed);
        }
        return t;
      }).toList();

      // Recalculate completionStatus
      final totalCount = updatedTasks.length;
      final completedCount = updatedTasks.where((t) => t.completed).length;
      
      String newStatus = 'Pending';
      if (completedCount == totalCount && totalCount > 0) {
        newStatus = 'Completed';
      } else if (completedCount > 0) {
        newStatus = 'In Progress';
      }

      final updatedSchedule = schedule.copyWith(
        scheduledTasks: updatedTasks,
        completionStatus: newStatus,
      );

      await saveSchedule(updatedSchedule);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<ScheduleModel> generateSchedule(String userId, DateTime date) async {
    try {
      // 1. Fetch Goals
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      final goals = goalsSnapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .where((g) => !g.isCompleted)
          .toList();

      // 2. Fetch AI coach insights to find peak productive window
      String peakFocusTime = "Morning"; // Morning (9-11), Afternoon (1-3), Evening (7-9)
      try {
        final insightDoc = await _firestore.collection('ai_insights').doc(userId).get();
        if (insightDoc.exists && insightDoc.data() != null) {
          final insight = AIInsightModel.fromMap(insightDoc.data()!, insightDoc.id);
          final text = insight.weeklyInsight.toLowerCase();
          if (text.contains('afternoon') || text.contains('1 pm')) {
            peakFocusTime = "Afternoon";
          } else if (text.contains('evening') || text.contains('7 pm')) {
            peakFocusTime = "Evening";
          }
        }
      } catch (_) {}

      // 3. Assemble tasks
      final List<ScheduledTask> tasks = [];
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Helper to construct DateTime slots
      DateTime makeTime(int hour, int minute) {
        return dateOnly.add(Duration(hours: hour, minutes: minute));
      }

      // Map out times based on productivity patterns
      int peakStartHour = 9;
      int peakEndHour = 10;
      if (peakFocusTime == "Afternoon") {
        peakStartHour = 13;
        peakEndHour = 14;
      } else if (peakFocusTime == "Evening") {
        peakStartHour = 19;
        peakEndHour = 20;
      }

      // Block 1: Peak focus Deep work
      tasks.add(ScheduledTask(
        id: 'task_deep_work',
        title: 'Deep Work: Peak Focus Sprint',
        category: 'Deep Work',
        startTime: makeTime(peakStartHour, 0),
        endTime: makeTime(peakEndHour, 30),
        completed: false,
      ));

      // Block 2: Break & Rest
      tasks.add(ScheduledTask(
        id: 'task_break',
        title: 'Break & Decompress',
        category: 'Break',
        startTime: makeTime(peakEndHour, 30),
        endTime: makeTime(peakEndHour + 1, 0),
        completed: false,
      ));

      // Block 3: Coding focus (standard scheduler window)
      tasks.add(ScheduledTask(
        id: 'task_coding',
        title: 'Coding Focus timer session',
        category: 'Coding',
        startTime: makeTime(11, 0),
        endTime: makeTime(12, 30),
        completed: false,
      ));

      // Block 4: Study block mapped to Goal
      String studyTitle = 'Study session: Review Goals';
      if (goals.isNotEmpty) {
        studyTitle = 'Study block: "${goals.first.title}"';
      }
      tasks.add(ScheduledTask(
        id: 'task_study',
        title: studyTitle,
        category: 'Study',
        startTime: makeTime(14, 0),
        endTime: makeTime(15, 30),
        completed: false,
      ));

      // Block 5: Late afternoon workout
      tasks.add(ScheduledTask(
        id: 'task_workout',
        title: 'Late afternoon Workout / Gym',
        category: 'Workout',
        startTime: makeTime(17, 0),
        endTime: makeTime(18, 0),
        completed: false,
      ));

      // Sort tasks by start time
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));

      final docId = _getDocId(userId, date);
      final newSchedule = ScheduleModel(
        id: docId,
        userId: userId,
        date: dateOnly,
        scheduledTasks: tasks,
        generatedByAI: true,
        completionStatus: 'Pending',
        createdAt: DateTime.now(),
      );

      await saveSchedule(newSchedule);
      return newSchedule;
    } catch (_) {
      rethrow;
    }
  }
}
