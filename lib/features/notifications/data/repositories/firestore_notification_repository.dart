// lib/features/notifications/data/repositories/firestore_notification_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _collection.doc(notification.id.isEmpty ? null : notification.id).set(notification.toMap());
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'isRead': true});
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _collection.doc(notificationId).delete();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> syncSystemNotifications(String userId) async {
    try {
      final now = DateTime.now();
      final todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final batch = _firestore.batch();

      // Helper to format time
      String formatTime(DateTime dt) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }

      // ─── 1. GOAL NOTIFICATIONS ───
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      final goals = goalsSnapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();

      for (final goal in goals) {
        if (goal.isCompleted) {
          // Goal completed notification
          final notifId = 'goal_completed_${goal.id}';
          final docRef = _collection.doc(notifId);
          batch.set(docRef, {
            'userId': userId,
            'title': 'Goal Completed! 🎉',
            'message': 'Congratulations! You have completed your goal: "${goal.title}".',
            'type': 'Goal',
            'isRead': false,
            'createdAt': goal.updatedAt.toIso8601String(),
          }, SetOptions(merge: true));
        } else {
          // Goal progress behind schedule
          final daysSinceCreated = now.difference(goal.createdAt).inDays;
          if (goal.progressPercentage < 25.0 && daysSinceCreated >= 2) {
            final notifId = 'goal_behind_${goal.id}';
            final docRef = _collection.doc(notifId);
            batch.set(docRef, {
              'userId': userId,
              'title': 'Goal Progress Behind Schedule ⚠️',
              'message': 'Your goal "${goal.title}" is currently at ${goal.progressPercentage.toStringAsFixed(0)}% progress.',
              'type': 'Goal',
              'isRead': false,
              'createdAt': now.toIso8601String(),
            }, SetOptions(merge: true));
          }

          // Goal milestone approaching (7-day default target)
          if (daysSinceCreated == 6) {
            final notifId = 'goal_deadline_${goal.id}';
            final docRef = _collection.doc(notifId);
            batch.set(docRef, {
              'userId': userId,
              'title': 'Goal Milestone Approaching 📅',
              'message': 'It has been 6 days since you set the goal "${goal.title}". Check your progress!',
              'type': 'Goal',
              'isRead': false,
              'createdAt': now.toIso8601String(),
            }, SetOptions(merge: true));
          }
        }
      }

      // ─── 2. SCHEDULE & ACTIVITY ALERTS ───
      final scheduleDocId = '${userId}_$todayString';
      final scheduleDoc = await _firestore.collection('schedules').doc(scheduleDocId).get();
      if (scheduleDoc.exists && scheduleDoc.data() != null) {
        final data = scheduleDoc.data()!;
        final tasksList = data['scheduledTasks'] as List? ?? const [];
        for (final t in tasksList) {
          final map = Map<String, dynamic>.from(t);
          final taskId = map['id'] as String? ?? '';
          final title = map['title'] as String? ?? '';
          final completed = map['completed'] as bool? ?? false;

          DateTime parseDate(dynamic val) {
            if (val == null) return DateTime.now();
            return DateTime.tryParse(val as String) ?? DateTime.now();
          }
          final startTime = parseDate(map['startTime']);
          final endTime = parseDate(map['endTime']);

          if (!completed) {
            // Check if starts soon (next 30 mins)
            final diffStart = startTime.difference(now);
            if (diffStart.inMinutes > 0 && diffStart.inMinutes <= 30) {
              final notifId = 'activity_due_$taskId';
              final docRef = _collection.doc(notifId);
              batch.set(docRef, {
                'userId': userId,
                'title': 'Activity Starting Soon ⏳',
                'message': 'Your scheduled task "$title" starts at ${formatTime(startTime)}.',
                'type': 'Activity',
                'isRead': false,
                'createdAt': now.toIso8601String(),
              }, SetOptions(merge: true));
            }

            // Check if missed (past end time)
            if (now.isAfter(endTime)) {
              final notifId = 'activity_missed_$taskId';
              final docRef = _collection.doc(notifId);
              batch.set(docRef, {
                'userId': userId,
                'title': 'Missed Activity 📝',
                'message': 'You missed the scheduled task "$title" (slotted for ${formatTime(startTime)} - ${formatTime(endTime)}).',
                'type': 'Activity',
                'isRead': false,
                'createdAt': now.toIso8601String(),
              }, SetOptions(merge: true));
            }
          } else {
            // Task completed notification
            final notifId = 'activity_completed_$taskId';
            final docRef = _collection.doc(notifId);
            batch.set(docRef, {
              'userId': userId,
              'title': 'Activity Completed! ✅',
              'message': 'You finished your scheduled task: "$title". Great work!',
              'type': 'Activity',
              'isRead': false,
              'createdAt': now.toIso8601String(),
            }, SetOptions(merge: true));
          }
        }
      }

      // ─── 3. SMART AI & FOCUS INSIGHTS ───
      final insightDoc = await _firestore.collection('ai_insights').doc(userId).get();
      if (insightDoc.exists && insightDoc.data() != null) {
        final insightData = insightDoc.data()!;
        final weeklyInsight = (insightData['weeklyInsight'] as String? ?? '').toLowerCase();

        // Detect peak focus window
        String peakTimeName = "Morning";
        int targetHour = 9;
        if (weeklyInsight.contains('afternoon') || weeklyInsight.contains('1 pm')) {
          peakTimeName = "Afternoon";
          targetHour = 13;
        } else if (weeklyInsight.contains('evening') || weeklyInsight.contains('7 pm')) {
          peakTimeName = "Evening";
          targetHour = 19;
        }

        final targetTime = DateTime(now.year, now.month, now.day, targetHour, 0);
        final timeDiff = targetTime.difference(now);
        if (timeDiff.inMinutes > 0 && timeDiff.inMinutes <= 15) {
          final notifId = 'ai_focus_time_$todayString';
          final docRef = _collection.doc(notifId);
          batch.set(docRef, {
            'userId': userId,
            'title': 'AI Coach Peak Productivity Alert 🧠',
            'message': 'Your best focus time ($peakTimeName window) begins in 15 minutes.',
            'type': 'AI',
            'isRead': false,
            'createdAt': now.toIso8601String(),
          }, SetOptions(merge: true));
        }
      }

      // ─── 4. STREAK WARNINGS ───
      final streakDoc = await _firestore.collection('streaks').doc(userId).get();
      if (streakDoc.exists && streakDoc.data() != null) {
        final streakData = streakDoc.data()!;
        final currentStreak = streakData['currentStreak'] as int? ?? 0;

        if (currentStreak > 0) {
          // Check completed focus sessions today
          final startOfToday = DateTime(now.year, now.month, now.day);
          final sessionsSnapshot = await _firestore
              .collection('focus_sessions')
              .where('userId', isEqualTo: userId)
              .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
              .get();
          
          final sessions = sessionsSnapshot.docs
              .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
              .toList();
          final completedToday = sessions.where((s) => s.completed).length;

          if (completedToday == 0) {
            final notifId = 'ai_streak_warning_$todayString';
            final docRef = _collection.doc(notifId);
            batch.set(docRef, {
              'userId': userId,
              'title': 'Protect Your Streak! 🔥',
              'message': 'You are 2 sessions away from extending your $currentStreak day streak.',
              'type': 'AI',
              'isRead': false,
              'createdAt': now.toIso8601String(),
            }, SetOptions(merge: true));
          }
        }
      }

      await batch.commit();
    } catch (_) {
      // Fail silently for system notification updates
    }
  }
}
