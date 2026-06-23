// lib/features/notifications/data/repositories/firestore_notification_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/reminder_model.dart';
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
  Stream<List<ReminderModel>> streamNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by reminderTime descending by default
      list.sort((a, b) => b.reminderTime.compareTo(a.reminderTime));
      return list;
    });
  }

  @override
  Future<void> createNotification(ReminderModel reminder) async {
    final docRef = reminder.id.isEmpty
        ? _collection.doc()
        : _collection.doc(reminder.id);

    final toSave = reminder.id.isEmpty
        ? reminder.copyWith(id: docRef.id)
        : reminder;

    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateNotification(ReminderModel reminder) async {
    await _collection.doc(reminder.id).set(reminder.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> syncSystemReminders(String userId) async {
    try {
      final now = DateTime.now();
      final todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final batch = _firestore.batch();

      // ─── 1. GOAL DEADLINE CHECK ───
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      final goals = goalsSnapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();

      for (final goal in goals) {
        if (!goal.isCompleted) {
          // Assume standard 7 days default goal duration from creation date
          final deadline = goal.createdAt.add(const Duration(days: 7));
          final daysRemaining = deadline.difference(now).inDays;

          if (daysRemaining >= 0 && daysRemaining < 3) {
            final reminderId = 'goal_deadline_${goal.id}';
            final docRef = _collection.doc(reminderId);

            final sysReminder = ReminderModel(
              id: reminderId,
              userId: userId,
              title: 'Goal Deadline Looming 📅',
              description: 'Your goal "${goal.title}" is due in $daysRemaining day(s). Make progress now!',
              reminderTime: now,
              type: 'Goal',
              completed: false,
              createdAt: now,
            );

            batch.set(docRef, sysReminder.toMap(), SetOptions(merge: true));
          }
        }
      }

      // ─── STREAK & FOCUS COMPLETED TODAY CHECKS ───
      final startOfToday = DateTime(now.year, now.month, now.day);
      final sessionsSnapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .get();
      
      final sessions = sessionsSnapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .where((s) => s.startTime.isAfter(startOfToday))
          .toList();
      final completedToday = sessions.where((s) => s.completed).length;

      // ─── 2. STREAK WARNING ───
      final streakDoc = await _firestore.collection('streaks').doc(userId).get();
      if (streakDoc.exists && streakDoc.data() != null) {
        final streakData = streakDoc.data()!;
        final currentStreak = streakData['currentStreak'] as int? ?? 0;

        if (currentStreak > 0 && completedToday == 0) {
          final reminderId = 'streak_warning_${userId}_$todayString';
          final docRef = _collection.doc(reminderId);

          final sysReminder = ReminderModel(
            id: reminderId,
            userId: userId,
            title: 'Protect Your Streak! 🔥',
            description: 'Extend your $currentStreak day streak by completing a focus session today.',
            reminderTime: now,
            type: 'Streak',
            completed: false,
            createdAt: now,
          );

          batch.set(docRef, sysReminder.toMap(), SetOptions(merge: true));
        }
      }

      // ─── 3. NO FOCUS TODAY WARNING ───
      if (completedToday == 0) {
        final reminderId = 'no_focus_warning_${userId}_$todayString';
        final docRef = _collection.doc(reminderId);

        final sysReminder = ReminderModel(
          id: reminderId,
          userId: userId,
          title: 'Stay Focused Today 🧠',
          description: "You haven't completed any focus sessions today. Start a focus timer to boost your productivity!",
          reminderTime: now,
          type: 'Focus',
          completed: false,
          createdAt: now,
        );

        batch.set(docRef, sysReminder.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (_) {
      // Fail silently for background sync operations
    }
  }
}
