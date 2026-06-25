// lib/features/ai_coach/data/repositories/firestore_ai_coach_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/ai_insight_model.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../../../activities/domain/models/activity_model.dart';
import '../../../focus_timer/domain/models/focus_session_model.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../streaks/domain/models/streak_model.dart';
import '../../../brain_games/domain/models/game_model.dart';
import '../../../achievements/domain/models/achievement_model.dart';
import '../../../student_hub/domain/models/subject_model.dart';
import '../../../student_hub/domain/models/attendance_model.dart';
import '../../../student_hub/domain/models/assignment_model.dart';
import '../../../student_hub/domain/models/placement_model.dart';
import '../../../exams/domain/models/exam_model.dart';
import '../../../exams/domain/models/revision_plan_model.dart';
import '../../../knowledge_vault/domain/models/note_model.dart';


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

      // 5. Fetch achievements
      List<AchievementModel> achievements = [];
      try {
        final achievementsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .get();
        achievements = achievementsSnapshot.docs
            .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {}

      // 6. Fetch brain games
      List<GameModel> brainGames = [];
      try {
        final brainGamesSnapshot = await _firestore
            .collection('brain_games')
            .where('userId', isEqualTo: userId)
            .get();
        brainGames = brainGamesSnapshot.docs
            .map((doc) => GameModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {}

      // 7. Fetch student data
      List<SubjectModel> subjects = [];
      List<AttendanceModel> attendanceLogs = [];
      List<AssignmentModel> assignments = [];
      List<PlacementModel> placements = [];
      try {
        final subjectsSnapshot = await _firestore
            .collection('subjects')
            .where('userId', isEqualTo: userId)
            .get();
        subjects = subjectsSnapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList();

        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: userId)
            .get();
        attendanceLogs = attendanceSnapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList();

        final assignmentsSnapshot = await _firestore
            .collection('assignments')
            .where('userId', isEqualTo: userId)
            .get();
        assignments = assignmentsSnapshot.docs
            .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
            .toList();

        final placementsSnapshot = await _firestore
            .collection('placement_progress')
            .where('userId', isEqualTo: userId)
            .get();
        placements = placementsSnapshot.docs
            .map((doc) => PlacementModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {}

      List<ExamModel> exams = [];
      List<RevisionPlanModel> revisionPlans = [];
      try {
        final examsSnapshot = await _firestore
            .collection('exams')
            .where('userId', isEqualTo: userId)
            .get();
        exams = examsSnapshot.docs
            .map((doc) => ExamModel.fromMap(doc.data(), doc.id))
            .toList();

        final plansSnapshot = await _firestore
            .collection('revision_plans')
            .where('userId', isEqualTo: userId)
            .get();
        revisionPlans = plansSnapshot.docs
            .map((doc) => RevisionPlanModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {}

      List<NoteModel> notes = [];
      try {
        final notesSnapshot = await _firestore
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .get();
        notes = notesSnapshot.docs
            .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {}

      // --- Calculations & Formulas ---
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      // Focus metrics
      final todaySessions = sessions.where((s) => s.startTime.isAfter(todayStart)).toList();
      final todaySessionsCount = todaySessions.length;
      final todayFocusMinutes = todaySessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      final thisWeekSessions = sessions.where((s) => s.startTime.isAfter(weekAgo)).toList();
      final thisWeekFocusMinutes = thisWeekSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      final lastWeekSessions = sessions
          .where((s) => s.startTime.isAfter(twoWeeksAgo) && s.startTime.isBefore(weekAgo))
          .toList();
      final lastWeekFocusMinutes = lastWeekSessions.fold<int>(0, (total, s) => total + s.durationMinutes);

      // Activity metrics
      final todayActivities = activities
          .where((a) => a.startTime.isAfter(todayStart))
          .toList();
      final todayActivitiesCount = todayActivities.length;

      final thisWeekActivities = activities.where((a) => a.startTime.isAfter(weekAgo)).toList();
      final thisWeekActivitiesCount = thisWeekActivities.length;

      // Goal metrics
      final totalGoalsCount = goals.length;
      final completedGoalsCount = goals.where((g) => g.isCompleted).length;
      final goalCompletionRate = totalGoalsCount > 0 ? (completedGoalsCount / totalGoalsCount) : 0.0;

      // Streak metrics
      final currentStreak = streak?.currentStreak ?? 0;

      // Brain games metrics
      final totalBrainGamesPlays = brainGames.fold<int>(0, (total, g) => total + g.totalPlays);

      // Achievements metrics
      final unlockedAchievementsCount = achievements.where((a) => a.unlocked).length;
      final thisWeekAchievementsCount = achievements
          .where((a) => a.unlocked && a.unlockedAt != null && a.unlockedAt!.isAfter(weekAgo))
          .length;

      // --- Weighted Productivity Score Formula (0-100) ---
      // 1. Focus duration (30%): Target 15 hours / week (900 mins)
      final focusScore = ((thisWeekFocusMinutes / 900.0) * 30.0).clamp(0.0, 30.0);
      // 2. Goal completion (20%)
      final goalScore = totalGoalsCount > 0 ? (goalCompletionRate * 20.0) : 20.0;
      // 3. Tasks completion (15%): Target 7 tasks / week
      final activityScore = ((thisWeekActivitiesCount / 7.0) * 15.0).clamp(0.0, 15.0);
      // 4. Streak consistency (15%): Target 5 days streak
      final streakScore = ((currentStreak / 5.0) * 15.0).clamp(0.0, 15.0);
      // 5. Brain games consistency (10%): Target 3 plays
      final brainScore = ((totalBrainGamesPlays / 3.0) * 10.0).clamp(0.0, 10.0);
      // 6. Achievements unlocked (10%): Target 5 unlocked
      final achievementScore = ((unlockedAchievementsCount / 5.0) * 10.0).clamp(0.0, 10.0);

      final productivityScore = (focusScore + goalScore + activityScore + streakScore + brainScore + achievementScore).round().clamp(0, 100);

      // --- Percentage Changes ---
      double getPercentageChange(double current, double previous) {
        if (previous == 0) return current > 0 ? 100.0 : 0.0;
        return ((current - previous) / previous) * 100.0;
      }
      final focusWeekChange = getPercentageChange(thisWeekFocusMinutes.toDouble(), lastWeekFocusMinutes.toDouble());

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

      // Peak Focus Time of Day
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

      // Student Hub metrics calculations
      double totalCredits = 0.0;
      double totalPoints = 0.0;
      for (final s in subjects) {
        if (s.isCompleted && s.gradePoint != null) {
          totalCredits += s.credits;
          totalPoints += (s.credits * s.gradePoint!);
        }
      }
      final currentCGPA = totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;

      final lowAttendanceWarnings = <String>[];
      for (final s in subjects) {
        final logs = attendanceLogs.where((log) => log.subjectId == s.id).toList();
        if (logs.isNotEmpty) {
          final presents = logs.where((log) => log.status == 'present').length;
          final absents = logs.where((log) => log.status == 'absent').length;
          final total = presents + absents;
          if (total > 0) {
            final rate = (presents / total) * 100.0;
            if (rate < 75.0) {
              lowAttendanceWarnings.add(
                "Attendance in '${s.name}' (${s.code}) is ${rate.toStringAsFixed(1)}%, which is below the 75% requirement. Attend upcoming classes! ⚠️"
              );
            }
          }
        }
      }

      final pendingAssignments = assignments.where((a) => a.status == 'Pending').toList();
      final urgentAssignments = pendingAssignments.where((a) {
        final difference = a.dueDate.difference(now).inDays;
        return difference >= 0 && difference <= 3;
      }).toList();

      final interviewingPlacements = placements.where((p) => p.status == 'Interviewing').toList();

      // --- 1. Daily AI Briefing ---
      String studentBrief = "";
      if (currentCGPA > 0) {
        studentBrief += " Your current CGPA is ${currentCGPA.toStringAsFixed(2)}.";
      }
      if (pendingAssignments.isNotEmpty) {
        studentBrief += " You have ${pendingAssignments.length} pending assignments (${urgentAssignments.length} due within 3 days).";
      }
      if (lowAttendanceWarnings.isNotEmpty) {
        studentBrief += " Critical: Attendance is low in ${lowAttendanceWarnings.length} subjects.";
      }

      final dailyBriefing = "Today, you completed $todaySessionsCount focus sessions, totaling $todayFocusMinutes minutes, and logged $todayActivitiesCount activities. "
          "Your current active streak is $currentStreak days. "
          "${todaySessionsCount > 0 ? 'You are doing great! Keep up the momentum.' : 'Start a focus session today to activate your daily productivity loop!'}"
          "$studentBrief";

      // --- 2. Weekly AI Review ---
      String studentWeekly = "";
      final completedThisWeek = assignments.where((a) => a.status == 'Submitted' && a.dueDate.isAfter(weekAgo)).length;
      if (completedThisWeek > 0) {
        studentWeekly += " You submitted $completedThisWeek assignments this week.";
      }
      if (placements.isNotEmpty) {
        final applicationsCount = placements.where((p) => p.createdAt.isAfter(weekAgo)).length;
        if (applicationsCount > 0) {
          studentWeekly += " You initiated $applicationsCount new job/internship applications.";
        }
      }

      final weeklyReview = "You logged $thisWeekFocusMinutes focus minutes across ${thisWeekSessions.length} sessions this week. "
          "This is a ${focusWeekChange >= 0 ? 'growth' : 'reduction'} of ${focusWeekChange.abs().toStringAsFixed(0)}% compared to last week. "
          "You completed $thisWeekActivitiesCount tasks and unlocked $thisWeekAchievementsCount achievements."
          "$studentWeekly";

      // --- 3. Productivity Insights ---
      String studentInsights = "";
      if (interviewingPlacements.isNotEmpty) {
        studentInsights += " You have active interviews with ${interviewingPlacements.length} companies: ${interviewingPlacements.map((p) => p.company).join(', ')}.";
      }

      final productivityInsights = "Your peak focus window occurs between $productiveTimeRange. "
          "Your top activity category is '$topCategory'. "
          "You have played $totalBrainGamesPlays total brain games training sessions, keeping your cognitive focus active."
          "$studentInsights";

      // --- 4. Focus Recommendations ---
      final focusRecommendations = <String>[
        "Schedule two 50-minute deep work sessions during your peak productivity hours ($productiveTimeRange).",
        "Take a structured 5-minute break after every 25 minutes of focus to maintain high performance.",
        "Connect your focus timer sessions directly to '$topCategory' activities to accurately map your cognitive logs."
      ];
      if (urgentAssignments.isNotEmpty) {
        focusRecommendations.add("Schedule a 45-minute study focus block for assignment '${urgentAssignments.first.title}' today.");
      }

      // --- 5. Goal Recommendations ---
      final goalRecommendations = <String>[];
      final activeGoals = goals.where((g) => g.status == 'Active' && !g.isCompleted).toList();
      if (goals.isEmpty) {
        goalRecommendations.add("Create your first personal milestone or goal to kickstart structured target tracking.");
      } else {
        if (activeGoals.isNotEmpty) {
          goalRecommendations.add("Devote your next deep work session specifically to making progress on goal '${activeGoals.first.title}'.");
          goalRecommendations.add("Set a minor milestone for '${activeGoals.first.title}' to break down the work.");
        }
        goalRecommendations.add("Review your goal completion rate (currently ${(goalCompletionRate * 100).toStringAsFixed(0)}%) and check off completed goals.");
      }
      if (lowAttendanceWarnings.isNotEmpty) {
        goalRecommendations.add("Set a goal to attend all classes for low-attendance subjects to recover attendance.");
      }

      // --- Exam Tracker Recommendations Integration ---
      if (exams.isNotEmpty) {
        final nowTemp = DateTime.now();
        final todayTemp = DateTime(nowTemp.year, nowTemp.month, nowTemp.day);
        final upcomingExams = exams.where((e) {
          final targetDate = DateTime(e.examDate.year, e.examDate.month, e.examDate.day);
          return targetDate.isAfter(todayTemp) || targetDate.isAtSameMomentAs(todayTemp);
        }).toList();

        if (upcomingExams.isNotEmpty) {
          upcomingExams.sort((a, b) => a.examDate.compareTo(b.examDate));
          final urgentExam = upcomingExams.first;
          final remainingDays = urgentExam.daysRemaining;

          focusRecommendations.add(
            "Upcoming Exam Alert: Your ${urgentExam.subject} exam is in $remainingDays ${remainingDays == 1 ? 'day' : 'days'}. Allocate focus blocks for review!"
          );

          final examPlans = revisionPlans.where((p) => p.examId == urgentExam.id).toList();
          if (examPlans.isEmpty) {
            goalRecommendations.add(
              "Revision Suggestion: Set up a study plan for '${urgentExam.subject}' by adding key syllabus topics in the Exam Tracker."
            );
          } else {
            final pending = examPlans.where((p) => !p.isCompleted).toList();
            if (pending.isNotEmpty) {
              focusRecommendations.add(
                "Smart Study Suggestion: Focus on revising the topic '${pending.first.topicName}' for ${urgentExam.subject}."
              );
            } else {
              focusRecommendations.add(
                "Great work! You have completed all revision topics for ${urgentExam.subject}."
              );
            }
          }

          goalRecommendations.add(
            "Study Target Recommendation: Dedicate ${urgentExam.dailyStudyGoalMinutes} minutes today to prepare for ${urgentExam.subject}."
          );
        }
      }

      // --- Knowledge Vault Recommendations Integration ---
      if (notes.isEmpty) {
        goalRecommendations.add(
          "Knowledge Vault Suggestion: Create your first study guide or note under the Knowledge Vault to centralize your resources."
        );
      } else {
        final studyNotes = notes.where((n) => n.category == 'Study Note').toList();
        if (studyNotes.isNotEmpty) {
          studyNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final recentStudyNote = studyNotes.first;
          focusRecommendations.add(
            "Revision Recommendation: Spend 15 minutes reviewing your recent study note on '${recentStudyNote.title}'."
          );
        }
        
        goalRecommendations.add(
          "Smart Note Suggestion: Categorize your ${notes.length} saved notes with tags to enable instant full-text filtering."
        );
      }

      // --- 6. Streak Predictions ---
      final streakPredictions = <String>[];
      final completedToday = todaySessions.where((s) => s.completed).length;
      if (currentStreak > 0) {
        if (completedToday > 0) {
          streakPredictions.add("Safe. Your streak is secure for today! 🔥");
        } else {
          streakPredictions.add("Warning: Complete at least one focus session today to preserve your $currentStreak-day streak! ⚠️");
        }
      } else {
        streakPredictions.add("Start a 25-minute focus session today to kickstart a new streak! 🚀");
      }
      streakPredictions.add("Maintain a consistent session start time to automatically form a strong daily habit chain.");
      streakPredictions.addAll(lowAttendanceWarnings);

      final summaryMap = {
        'dailyBriefing': dailyBriefing,
        'weeklyReview': weeklyReview,
        'productivityInsights': productivityInsights,
      };

      final recommendationsMap = {
        'focus': focusRecommendations,
        'goals': goalRecommendations,
        'streaks': streakPredictions,
      };


      final insightReport = AIInsightModel(
        id: userId,
        userId: userId,
        summary: summaryMap,
        recommendations: recommendationsMap,
        productivityScore: productivityScore,
        generatedAt: now,
      );

      // Save to Firestore
      await _collection.doc(userId).set(insightReport.toMap());
      return insightReport;
    } catch (_) {
      rethrow;
    }
  }
}
