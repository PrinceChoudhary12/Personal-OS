// lib/features/focus_timer/presentation/providers/focus_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/focus_session_model.dart';
import '../../domain/repositories/focus_repository.dart';

final focusSessionsStreamProvider = StreamProvider<List<FocusSessionModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final FocusRepository repo = ref.watch(focusRepositoryProvider);
  return repo.streamSessions(user.uid);
});
