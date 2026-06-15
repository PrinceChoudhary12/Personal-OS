// lib/features/focus_timer/presentation/providers/focus_session_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firestore_focus_session_repository.dart';
import '../../domain/models/focus_session_model.dart';
import '../../domain/repositories/focus_session_repository.dart';

// --- Focus Session Repository Provider ---
final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FirestoreFocusSessionRepository();
});

// --- Stream of Focus Sessions for current user ---
final focusSessionsStreamProvider = StreamProvider<List<FocusSessionModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(focusSessionRepositoryProvider);
  return repo.streamFocusSessions(user.uid);
});
