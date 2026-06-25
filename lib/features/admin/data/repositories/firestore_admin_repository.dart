// lib/features/admin/data/repositories/firestore_admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore;

  FirestoreAdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Access Control ───────────────────────────────────────────────────────
  @override
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ── Platform Stats ───────────────────────────────────────────────────────
  @override
  Future<Map<String, int>> getPlatformStats() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final totalUsers = usersSnap.docs.length;

      // Count active users (logged in within last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      int activeUsers = 0;
      int totalXP = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final lastLogin = data['lastLogin'];
        if (lastLogin != null) {
          DateTime? d;
          if (lastLogin is String) {
            d = DateTime.tryParse(lastLogin);
          } else {
            try {
              d = (lastLogin as dynamic).toDate() as DateTime;
            } catch (_) {}
          }
          if (d != null && d.isAfter(weekAgo)) {
            activeUsers++;
          }
        }
        // Sum XP from user profiles
        final xpDoc = await _firestore
            .collection('users')
            .doc(doc.id)
            .collection('gamification')
            .doc('xp')
            .get();
        if (xpDoc.exists) {
          totalXP += (xpDoc.data()?['totalXp'] as num? ?? 0).toInt();
        }
      }

      // Count goals
      final goalsSnap = await _firestore.collectionGroup('goals').get();
      final totalGoals = goalsSnap.docs.length;

      // Count activities
      final activitiesSnap = await _firestore.collectionGroup('activities').get();
      final totalActivities = activitiesSnap.docs.length;

      // Count brain game plays
      final gamesSnap = await _firestore.collectionGroup('brain_games').get();
      int totalPlays = 0;
      for (final doc in gamesSnap.docs) {
        totalPlays += (doc.data()['totalPlays'] as num? ?? 0).toInt();
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalGoals': totalGoals,
        'totalActivities': totalActivities,
        'totalXP': totalXP,
        'brainGamesPlayed': totalPlays,
      };
    } catch (_) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalGoals': 0,
        'totalActivities': 0,
        'totalXP': 0,
        'brainGamesPlayed': 0,
      };
    }
  }

  // ── User Management ──────────────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snap = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> users = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        // Fetch XP for each user
        final xpDoc = await _firestore
            .collection('users')
            .doc(doc.id)
            .collection('gamification')
            .doc('xp')
            .get();
        final xp = (xpDoc.data()?['totalXp'] as num? ?? 0).toInt();
        final level = (xpDoc.data()?['level'] as num? ?? 1).toInt();

        users.add({
          'uid': doc.id,
          'displayName': data['displayName'] ?? '',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'] ?? '',
          'createdAt': data['createdAt'] ?? '',
          'lastLogin': data['lastLogin'] ?? '',
          'xp': xp,
          'level': level,
        });
      }
      return users;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document and subcollections
      final userRef = _firestore.collection('users').doc(uid);

      // Delete known subcollections
      final subcollections = [
        'activities', 'focus_sessions', 'goals', 'streaks',
        'analytics', 'ai_coach_insights', 'scheduler_events',
        'notifications', 'gamification', 'achievements',
        'daily_challenges', 'brain_games', 'habits',
        'student_ai_chats',
      ];

      for (final sub in subcollections) {
        final subSnap = await userRef.collection(sub).get();
        final batch = _firestore.batch();
        for (final doc in subSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await userRef.delete();
    } catch (_) {}
  }

  @override
  Future<void> resetUserData(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final subcollections = [
        'activities', 'focus_sessions', 'goals',
        'analytics', 'achievements', 'daily_challenges',
        'brain_games', 'habits', 'student_ai_chats',
      ];

      for (final sub in subcollections) {
        final subSnap = await userRef.collection(sub).get();
        final batch = _firestore.batch();
        for (final doc in subSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Reset XP
      await userRef.collection('gamification').doc('xp').set({
        'currentXp': 0,
        'totalXp': 0,
        'level': 1,
        'nextLevelXp': 100,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Announcements ────────────────────────────────────────────────────────
  @override
  Stream<List<AnnouncementModel>> streamAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore.collection('announcements').add(announcement.toMap());
    } catch (_) {}
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
    } catch (_) {}
  }

  // ── Feedback ─────────────────────────────────────────────────────────────
  @override
  Stream<List<FeedbackModel>> streamFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> deleteFeedback(String id) async {
    try {
      await _firestore.collection('feedback').doc(id).delete();
    } catch (_) {}
  }
}
