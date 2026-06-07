// lib/features/auth/data/repositories/firebase_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;

  FirebaseAuthRepository({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  // --- Auth State Stream ---

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _auth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return _mapFirebaseUserToModel(fbUser);
    });
  }

  // --- Sign Up ---

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name in Firebase
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      final updated = _auth.currentUser;
      if (updated == null) throw const AuthException('Sign up failed.');
      return _mapFirebaseUserToModel(updated);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (_) {
      throw const AuthException('An unexpected error occurred during sign up.');
    }
  }

  // --- Sign In ---

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) throw const AuthException('Login failed.');
      return _mapFirebaseUserToModel(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (_) {
      throw const AuthException('An unexpected error occurred during sign in.');
    }
  }

  // --- Sign Out ---

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  // --- Get Current User ---

  @override
  Future<UserModel?> getCurrentUserData() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _mapFirebaseUserToModel(fbUser);
  }

  // --- Private Mapper ---

  UserModel _mapFirebaseUserToModel(fb.User fbUser) {
    return UserModel(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? 'Personal OS User',
      photoUrl: fbUser.photoURL ?? '',
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      preferences: const {},
    );
  }
}
