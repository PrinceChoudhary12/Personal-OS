// lib/features/auth/domain/repositories/auth_repository.dart
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUserData();
}
