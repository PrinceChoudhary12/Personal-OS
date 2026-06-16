// lib/features/analytics/data/repositories/firestore_analytics_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/analytics_model.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../goals/domain/models/goal_model.dart';

class FirestoreAnalyticsRepository implements AnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirestoreAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('analytics');

  @override
  Future<AnalyticsModel?> getAnalytics(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AnalyticsModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> saveAnalytics(AnalyticsModel analytics) async {
    try {
      await _collection.doc(analytics.userId).set(
            analytics.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<AnalyticsModel?> streamAnalytics(String userId) {
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AnalyticsModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<AnalyticsModel> calculateAndSaveAnalytics(String userId) async {
    try {
      // 1. Fetch activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();
      final activities = activitiesSnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. Fetch focus sessions
      final sessionsSnapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();
      final sessions = sessionsSnapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .toList();

      // 3. Fetch goals
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      final goals = goalsSnapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();

      // --- Compute Calculations ---
      final totalActivities = activities.length;
      final totalFocusTime = sessions.fold<int>(0, (total, s) => total + s.durationMinutes);
      final averageSessionDuration = sessions.isEmpty ? 0.0 : totalFocusTime / sessions.length;
      final goalCompletionRate = goals.completionRate;

      // Category distribution
      final categoryBreakdown = <String, int>{};
      for (final a in activities) {
        categoryBreakdown[a.category] = (categoryBreakdown[a.category] ?? 0) + 1;
      }

      // Daily Productivity: Last 7 days (including today)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dailyProductivity = List<double>.filled(7, 0.0);
      for (final s in sessions) {
        final sessionDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        final difference = today.difference(sessionDate).inDays;
        if (difference >= 0 && difference < 7) {
          dailyProductivity[6 - difference] += s.durationMinutes.toDouble();
        }
      }

      // Weekly Productivity: Last 4 weeks
      final weeklyProductivity = List<double>.filled(4, 0.0);
      for (final s in sessions) {
        final sessionDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        final differenceDays = today.difference(sessionDate).inDays;
        final weekIndex = differenceDays ~/ 7;
        if (weekIndex >= 0 && weekIndex < 4) {
          weeklyProductivity[3 - weekIndex] += s.durationMinutes.toDouble();
        }
      }

      // Monthly Productivity: Last 6 months
      final monthlyProductivity = List<double>.filled(6, 0.0);
      for (final s in sessions) {
        final diffMonths = (today.year - s.startTime.year) * 12 + today.month - s.startTime.month;
        if (diffMonths >= 0 && diffMonths < 6) {
          monthlyProductivity[5 - diffMonths] += s.durationMinutes.toDouble();
        }
      }

      final analytics = AnalyticsModel(
        id: userId,
        userId: userId,
        totalActivities: totalActivities,
        totalFocusTime: totalFocusTime,
        averageSessionDuration: averageSessionDuration,
        goalCompletionRate: goalCompletionRate,
        categoryBreakdown: categoryBreakdown,
        dailyProductivity: dailyProductivity,
        weeklyProductivity: weeklyProductivity,
        monthlyProductivity: monthlyProductivity,
        createdAt: DateTime.now(),
      );

      await saveAnalytics(analytics);
      return analytics;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> logEvent(
    String userId,
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _firestore.collection('analytics_events').add({
        'userId': userId,
        'eventName': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      rethrow;
    }
  }
}
