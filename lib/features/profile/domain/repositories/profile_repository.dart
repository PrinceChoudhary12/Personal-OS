// lib/features/profile/domain/repositories/profile_repository.dart

import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String uid);
  Stream<UserProfile?> watchProfile(String uid);
  Future<void> saveProfile(UserProfile profile);
}
