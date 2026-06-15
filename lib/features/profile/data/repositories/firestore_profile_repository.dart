// lib/features/profile/data/repositories/firestore_profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        // Create default profile if it doesn't exist yet
        final currentUser = _auth.currentUser;
        final now = DateTime.now();
        final defaultProfile = UserProfile(
          uid: uid,
          email: currentUser?.email ?? '',
          displayName: currentUser?.displayName ?? 'Personal OS User',
          photoUrl: currentUser?.photoURL ?? '',
          university: '',
          course: '',
          semester: 1,
          skills: const [],
          careerGoal: '',
          bio: '',
          dailyGoalHours: 0.0,
          weeklyGoalHours: 0.0,
          preferredStudyTime: 'Morning',
          createdAt: now,
          updatedAt: now,
        );
        await saveProfile(defaultProfile);
        return defaultProfile;
      }
      return UserProfile.fromMap(doc.data()!, uid);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        // Create default profile if it doesn't exist yet
        final currentUser = _auth.currentUser;
        final now = DateTime.now();
        final defaultProfile = UserProfile(
          uid: uid,
          email: currentUser?.email ?? '',
          displayName: currentUser?.displayName ?? 'Personal OS User',
          photoUrl: currentUser?.photoURL ?? '',
          university: '',
          course: '',
          semester: 1,
          skills: const [],
          careerGoal: '',
          bio: '',
          dailyGoalHours: 0.0,
          weeklyGoalHours: 0.0,
          preferredStudyTime: 'Morning',
          createdAt: now,
          updatedAt: now,
        );
        await saveProfile(defaultProfile);
        return defaultProfile;
      }
      return UserProfile.fromMap(doc.data()!, uid);
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.uid).set(
            profile.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      rethrow;
    }
  }
}
