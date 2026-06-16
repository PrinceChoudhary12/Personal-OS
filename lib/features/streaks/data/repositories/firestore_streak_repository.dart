// lib/features/streaks/data/repositories/firestore_streak_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/streak_model.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../../activities/domain/models/activity_model.dart';

class FirestoreStreakRepository implements StreakRepository {
  final FirebaseFirestore _firestore;

  FirestoreStreakRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('streaks');

  @override
  Stream<StreakModel?> streamStreak(String userId) {
    return _collection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? StreakModel.fromMap(doc.data()!, doc.id)
            : null);
  }

  @override
  Future<StreakModel?> getStreakByUserId(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return StreakModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateStreak(StreakModel streak) async {
    try {
      await _collection.doc(streak.userId).set(
            streak.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> initializeStreak(String userId) async {
    try {
      final existing = await getStreakByUserId(userId);
      if (existing == null) {
        final newStreak = StreakModel(
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 30)),
          history: const [],
        );
        await updateStreak(newStreak);
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<StreakModel> calculateStreakFromActivities(String userId) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      final activities = activitiesSnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();

      final focusSnapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();

      final List<DateTime> sessionStartTimes = [];
      for (final doc in focusSnapshot.docs) {
        final data = doc.data();
        final startTimeVal = data['startTime'];
        if (startTimeVal != null) {
          DateTime? dt;
          if (startTimeVal is String) {
            dt = DateTime.tryParse(startTimeVal);
          } else if (startTimeVal is Timestamp) {
            dt = startTimeVal.toDate();
          }
          if (dt != null) {
            sessionStartTimes.add(dt);
          }
        }
      }

      if (activities.isEmpty && sessionStartTimes.isEmpty) {
        final streak = StreakModel(
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 30)),
          history: const [],
        );
        await updateStreak(streak);
        return streak;
      }

      // Extract unique local dates (YYYY-MM-DD)
      final Set<String> activityDates = activities.map((a) {
        final local = a.startTime.toLocal();
        return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      }).toSet();

      for (final startTime in sessionStartTimes) {
        final local = startTime.toLocal();
        activityDates.add('${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}');
      }

      final sortedDateStrings = activityDates.toList()..sort((a, b) => b.compareTo(a)); // desc
      final sortedDates = sortedDateStrings.map((s) => DateTime.parse(s)).toList();

      // Current Streak calculation
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      int currentStreak = 0;
      bool hasActivityToday = activityDates.contains(todayStr);
      bool hasActivityYesterday = activityDates.contains(yesterdayStr);

      if (hasActivityToday || hasActivityYesterday) {
        var checkDate = hasActivityToday ? DateTime.parse(todayStr) : DateTime.parse(yesterdayStr);
        while (true) {
          final checkStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          if (activityDates.contains(checkStr)) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      // Longest Streak calculation
      int longestStreak = 0;
      int tempStreak = 0;
      final ascendingDates = sortedDates.reversed.toList();
      DateTime? prevDate;

      for (final date in ascendingDates) {
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        }
        prevDate = date;
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;

      final lastActivity = sortedDates.isNotEmpty ? sortedDates.first : DateTime.now().subtract(const Duration(days: 30));

      final streak = StreakModel(
        userId: userId,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActivityDate: lastActivity,
        history: activityDates.toList()..sort(),
      );

      await updateStreak(streak);
      return streak;
    } catch (_) {
      rethrow;
    }
  }
}
