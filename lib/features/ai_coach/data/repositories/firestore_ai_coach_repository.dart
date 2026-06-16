// lib/features/ai_coach/data/repositories/firestore_ai_coach_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/ai_insight_model.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../streaks/domain/models/streak_model.dart';

class FirestoreAICoachRepository implements AICoachRepository {
  final FirebaseFirestore _firestore;

  FirestoreAICoachRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('ai_insights');

  @override
  Future<AIInsightModel?> getLatestInsight(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AIInsightModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AIInsightModel?> streamLatestInsight(String userId) {
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AIInsightModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<AIInsightModel> generateAndSaveInsights(String userId) async {
    try {
      // 1. Fetch activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();
      final activities = activitiesSnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. Fetch goals
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      final goals = goalsSnapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();

      // 3. Fetch streak
      StreakModel? streak;
      try {
        final streakDoc = await _firestore.collection('streaks').doc(userId).get();
        if (streakDoc.exists && streakDoc.data() != null) {
          streak = StreakModel.fromMap(streakDoc.data()!, streakDoc.id);
        }
      } catch (_) {}

      // 4. Fetch completed focus sessions
      final sessionsSnapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();
      final sessions = sessionsSnapshot.docs
          .map((doc) => FocusSessionModel.fromMap(doc.data(), doc.id))
          .toList();

      // --- Calculations & Formulas ---
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      final twoMonthsAgo = now.subtract(const Duration(days: 60));

      // 4.1 Today's focus sessions count
      final todaySessions = sessions.where((s) => s.startTime.isAfter(todayStart)).toList();
      final todaySessionsCount = todaySessions.length;
      final todayFocusMinutes = todaySessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      // 4.2 Weekly focus minutes
      final thisWeekSessions = sessions.where((s) => s.startTime.isAfter(weekAgo)).toList();
      final thisWeekFocusMinutes = thisWeekSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      final lastWeekSessions = sessions.where((s) => s.startTime.isAfter(twoWeeksAgo) && s.startTime.isBefore(weekAgo)).toList();
      final lastWeekFocusMinutes = lastWeekSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      // 4.3 Monthly focus minutes
      final thisMonthSessions = sessions.where((s) => s.startTime.isAfter(monthAgo)).toList();
      final thisMonthFocusMinutes = thisMonthSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      final lastMonthSessions = sessions.where((s) => s.startTime.isAfter(twoMonthsAgo) && s.startTime.isBefore(monthAgo)).toList();
      final lastMonthFocusMinutes = lastMonthSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      // 4.4 Activities counts
      final thisWeekActivities = activities.where((a) => a.startTime.isAfter(weekAgo)).toList();
      final thisWeekActivitiesCount = thisWeekActivities.length;

      final lastWeekActivities = activities.where((a) => a.startTime.isAfter(twoWeeksAgo) && a.startTime.isBefore(weekAgo)).toList();
      final lastWeekActivitiesCount = lastWeekActivities.length;

      final thisMonthActivities = activities.where((a) => a.startTime.isAfter(monthAgo)).toList();
      final thisMonthActivitiesCount = thisMonthActivities.length;

      final lastMonthActivities = activities.where((a) => a.startTime.isAfter(twoMonthsAgo) && a.startTime.isBefore(monthAgo)).toList();
      final lastMonthActivitiesCount = lastMonthActivities.length;

      // 4.5 Goal stats
      final totalGoalsCount = goals.length;
      final completedGoalsCount = goals.where((g) => g.isCompleted).length;
      final goalCompletionRate = totalGoalsCount > 0 ? (completedGoalsCount / totalGoalsCount) : 0.0;

      // 4.6 Streak stats
      final currentStreak = streak?.currentStreak ?? 0;

      // --- Weighted Productivity Score Formula (0-100) ---
      // Weight 1: Focus Time (35%): Target 15 hours / week (900 mins)
      final focusScore = ((thisWeekFocusMinutes / 900.0) * 35.0).clamp(0.0, 35.0);
      // Weight 2: Goal Completion Rate (25%)
      final goalScore = totalGoalsCount > 0 ? (goalCompletionRate * 25.0) : 25.0; // default 25 if no goals
      // Weight 3: Activity Completion (20%): Target 7 tasks / week
      final activityScore = ((thisWeekActivitiesCount / 7.0) * 20.0).clamp(0.0, 20.0);
      // Weight 4: Streak Consistency (20%): Target 5 days streak
      final streakScore = ((currentStreak / 5.0) * 20.0).clamp(0.0, 20.0);

      final productivityScore = (focusScore + goalScore + activityScore + streakScore).round().clamp(0, 100);

      // --- Percentage Changes for Trend Analysis ---
      double getPercentageChange(double current, double previous) {
        if (previous == 0) return current > 0 ? 100.0 : 0.0;
        return ((current - previous) / previous) * 100.0;
      }

      final focusWeekChange = getPercentageChange(thisWeekFocusMinutes.toDouble(), lastWeekFocusMinutes.toDouble());
      final focusMonthChange = getPercentageChange(thisMonthFocusMinutes.toDouble(), lastMonthFocusMinutes.toDouble());
      final activityWeekChange = getPercentageChange(thisWeekActivitiesCount.toDouble(), lastWeekActivitiesCount.toDouble());
      final activityMonthChange = getPercentageChange(thisMonthActivitiesCount.toDouble(), lastMonthActivitiesCount.toDouble());

      final trendComparison = {
        'thisWeekFocusMinutes': thisWeekFocusMinutes,
        'lastWeekFocusMinutes': lastWeekFocusMinutes,
        'focusWeekChangePercentage': focusWeekChange,
        'thisMonthFocusMinutes': thisMonthFocusMinutes,
        'lastMonthFocusMinutes': lastMonthFocusMinutes,
        'focusMonthChangePercentage': focusMonthChange,
        'thisWeekActivities': thisWeekActivitiesCount,
        'lastWeekActivities': lastWeekActivitiesCount,
        'activityWeekChangePercentage': activityWeekChange,
        'thisMonthActivities': thisMonthActivitiesCount,
        'lastMonthActivities': lastMonthActivitiesCount,
        'activityMonthChangePercentage': activityMonthChange,
      };

      // --- AI Summaries & Insights Generation ---
      // Determine Top Category
      final categoryCounts = <String, int>{};
      for (final a in activities) {
        categoryCounts[a.category] = (categoryCounts[a.category] ?? 0) + 1;
      }
      String topCategory = 'Coding';
      int maxCategoryCount = 0;
      categoryCounts.forEach((cat, cnt) {
        if (cnt > maxCategoryCount) {
          maxCategoryCount = cnt;
          topCategory = cat;
        }
      });

      // Time of Day Analysis
      int morningSessions = 0;
      int afternoonSessions = 0;
      int eveningSessions = 0;
      for (final s in sessions) {
        final hour = s.startTime.hour;
        if (hour >= 6 && hour < 12) {
          morningSessions++;
        } else if (hour >= 12 && hour < 17) {
          afternoonSessions++;
        } else {
          eveningSessions++;
        }
      }
      String productiveTimeRange = "9 AM and 11 AM";
      if (morningSessions >= afternoonSessions && morningSessions >= eveningSessions) {
        productiveTimeRange = "9 AM and 11 AM";
      } else if (afternoonSessions >= morningSessions && afternoonSessions >= eveningSessions) {
        productiveTimeRange = "1 PM and 3 PM";
      } else {
        productiveTimeRange = "7 PM and 9 PM";
      }

      // Generate Summaries
      final dailySummary = "You completed $todaySessionsCount focus sessions today, totaling $todayFocusMinutes minutes. "
          "${todaySessionsCount > 0 ? 'Excellent work showing up today!' : 'Let\'s start a Pomodoro timer to unlock your focus score.'}";

      final weeklySummary = "This week you completed $thisWeekFocusMinutes focus minutes across ${thisWeekSessions.length} sessions, "
          "representing a ${focusWeekChange >= 0 ? 'growth' : 'decrease'} of ${focusWeekChange.abs().toStringAsFixed(0)}% compared to last week. "
          "You completed $thisWeekActivitiesCount tasks with a goal completion rate of ${(goalCompletionRate * 100).toStringAsFixed(0)}%.";

      final monthlySummary = "Over the past 30 days, your focus duration has reached ${(thisMonthFocusMinutes / 60.0).toStringAsFixed(1)} hours. "
          "Your overall focus consistency has changed by ${focusMonthChange.toStringAsFixed(0)}% month-over-month. "
          "Your streak reached a peak of ${streak?.longestStreak ?? 0} days.";

      // Daily Advice
      String dailyAdvice;
      if (todaySessionsCount >= 2) {
        dailyAdvice = "You've crushed your daily targets! Continue this excellent momentum tomorrow.";
      } else {
        final needed = 2 - todaySessionsCount;
        dailyAdvice = "Complete $needed more focus session${needed > 1 ? 's' : ''} to maintain your streak.";
      }

      // Weekly Insight
      final weeklyInsight = "You are most productive between $productiveTimeRange. Protect this peak focus window by minimizing interruptions.";

      // Recommendations Lists
      final goalRecommendations = <String>[];
      if (goals.isEmpty) {
        goalRecommendations.add("Create your first goal in the '$topCategory' category to outline your target milestones.");
      } else {
        final activeGoals = goals.where((g) => g.status == 'Active' && !g.isCompleted).toList();
        if (activeGoals.isNotEmpty) {
          final target = activeGoals.first;
          goalRecommendations.add("Focus on '${target.title}' this week. Devote two 50-minute deep work sessions to make major progress.");
        }
        goalRecommendations.add("Consider setting a secondary goal in '$topCategory' to track peripheral learning items.");
      }

      final focusImprovementTips = <String>[
        "Your peak focus occurs during the window of $productiveTimeRange. Put your phone in Do Not Disturb during these sessions.",
        "Your top activity category is '$topCategory'. Try linking your focus sessions to these tasks using the selector in the Timer screen.",
        "Take a mandatory 5-minute break after completing a 25-minute Pomodoro timer to prevent cognitive fatigue."
      ];

      final timeManagementSuggestions = <String>[
        "Schedule two blocks of 50-minute Deep Work sessions around $productiveTimeRange when your cognitive energy is highest.",
        "Review your pending list of ${activities.length} logged tasks and delegate 30 minutes to review completed items.",
        "Set a weekly calendar buffer on Fridays to reflect on your goal milestones and adjust next week's focus target hours."
      ];

      final productivityWarnings = <String>[];
      if (focusWeekChange < -15) {
        productivityWarnings.add("Your focus minutes fell by ${focusWeekChange.abs().toStringAsFixed(0)}% this week compared to last week.");
      }
      if (currentStreak < 2) {
        productivityWarnings.add("Your active streak is currently $currentStreak. Complete a focus session today to build consistency!");
      }
      if (productivityWarnings.isEmpty) {
        productivityWarnings.add("No productivity warnings! You are maintaining a healthy balance and focus rate.");
      }

      final goalSuggestions = goals.isEmpty
          ? ["Create a goal to study or code daily."]
          : goals.take(2).map((g) => "Spend 45 minutes on '${g.title}' to boost completion progress.").toList();

      final insightReport = AIInsightModel(
        id: userId,
        userId: userId,
        productivityScore: productivityScore,
        dailySummary: dailySummary,
        weeklySummary: weeklySummary,
        monthlySummary: monthlySummary,
        goalRecommendations: goalRecommendations,
        focusImprovementTips: focusImprovementTips,
        timeManagementSuggestions: timeManagementSuggestions,
        productivityWarnings: productivityWarnings,
        dailyAdvice: dailyAdvice,
        weeklyInsight: weeklyInsight,
        goalSuggestions: goalSuggestions,
        trendComparison: trendComparison,
        createdAt: DateTime.now(),
      );

      // Save to Firestore cached collection
      await _collection.doc(userId).set(insightReport.toMap());
      return insightReport;
    } catch (_) {
      rethrow;
    }
  }
}
