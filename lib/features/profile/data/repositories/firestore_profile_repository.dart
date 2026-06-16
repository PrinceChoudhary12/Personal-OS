// lib/features/profile/data/repositories/firestore_profile_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('👤 [PROFILE REPO] getProfile called for uid: $uid');
      final docRef = _usersCollection.doc(uid);
      debugPrint('👤 [PROFILE REPO] Firestore document path: ${docRef.path}');

      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint('👤 [PROFILE REPO] Profile document does not exist. Creating default profile...');
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
        debugPrint('👤 [PROFILE REPO] Default profile successfully created and saved for uid: $uid');
        return defaultProfile;
      }

      final profile = UserProfile.fromMap(doc.data()!, uid);
      debugPrint('👤 [PROFILE REPO] getProfile parsed successfully for user: ${profile.displayName}');
      return profile;
    } catch (e, stack) {
      debugPrint('🚨 [PROFILE REPO] Error fetching profile for uid $uid: $e\n$stack');
      rethrow;
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    debugPrint('👤 [PROFILE REPO] watchProfile stream initialized for uid: $uid');
    final docRef = _usersCollection.doc(uid);
    debugPrint('👤 [PROFILE REPO] Watch path: ${docRef.path}');

    return docRef.snapshots().asyncMap((doc) async {
      debugPrint('👤 [PROFILE REPO] watchProfile snapshot received. exists: ${doc.exists}');
      try {
        if (!doc.exists) {
          debugPrint('👤 [PROFILE REPO] Snapshot document does not exist. Initiating asynchronous default profile creation...');
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

          // Save default profile asynchronously (do not await) to prevent blocking the stream/deadlocks
          saveProfile(defaultProfile).then((_) {
            debugPrint('👤 [PROFILE REPO] Default profile saved asynchronously for uid: $uid');
          }).catchError((e) {
            debugPrint('🚨 [PROFILE REPO] Asynchronous default profile save failed for uid: $uid, error: $e');
          });

          debugPrint('👤 [PROFILE REPO] Emitting default profile immediately to resolve UI loading states');
          return defaultProfile;
        }

        final data = doc.data();
        if (data == null) {
          debugPrint('👤 [PROFILE REPO] Document exists but data is null. Returning null.');
          return null;
        }

        final profile = UserProfile.fromMap(data, uid);
        debugPrint('👤 [PROFILE REPO] watchProfile parsed successfully: ${profile.displayName}');
        return profile;
      } catch (e, stack) {
        debugPrint('🚨 [PROFILE REPO] Error inside watchProfile stream mapper for uid $uid: $e\n$stack');
        rethrow;
      }
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    try {
      debugPrint('👤 [PROFILE REPO] saveProfile called for uid: ${profile.uid}');
      await _usersCollection.doc(profile.uid).set(
            profile.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('👤 [PROFILE REPO] saveProfile completed successfully for uid: ${profile.uid}');
    } catch (e, stack) {
      debugPrint('🚨 [PROFILE REPO] Error saving profile for uid ${profile.uid}: $e\n$stack');
      rethrow;
    }
  }
}
