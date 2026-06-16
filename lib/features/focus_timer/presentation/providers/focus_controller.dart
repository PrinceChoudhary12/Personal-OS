// lib/features/focus_timer/presentation/providers/focus_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/focus_session_model.dart';

class FocusState {
  final int initialDurationSeconds;
  final int durationLeftSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;
  final String? linkedActivityId;
  final String? currentSessionId;
  final String sessionType; // 'Pomodoro', 'Deep Work', 'Custom'

  const FocusState({
    required this.initialDurationSeconds,
    required this.durationLeftSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.isCompleted,
    this.linkedActivityId,
    this.currentSessionId,
    required this.sessionType,
  });

  FocusState copyWith({
    int? initialDurationSeconds,
    int? durationLeftSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isCompleted,
    String? linkedActivityId,
    String? currentSessionId,
    String? sessionType,
  }) {
    return FocusState(
      initialDurationSeconds: initialDurationSeconds ?? this.initialDurationSeconds,
      durationLeftSeconds: durationLeftSeconds ?? this.durationLeftSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessionType: sessionType ?? this.sessionType,
    );
  }
}

class FocusController extends StateNotifier<FocusState> {
  final Ref _ref;
  Timer? _ticker;
  DateTime? _sessionStartTime;

  FocusController(this._ref)
      : super(const FocusState(
          initialDurationSeconds: 25 * 60,
          durationLeftSeconds: 25 * 60,
          isRunning: false,
          isPaused: false,
          isCompleted: false,
          linkedActivityId: null,
          currentSessionId: null,
          sessionType: 'Pomodoro',
        ));

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void setPreset(int minutes, String type) {
    _ticker?.cancel();
    state = FocusState(
      initialDurationSeconds: minutes * 60,
      durationLeftSeconds: minutes * 60,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      linkedActivityId: state.linkedActivityId,
      currentSessionId: null,
      sessionType: type,
    );
  }

  void setCustomDurationSeconds(int seconds) {
    _ticker?.cancel();
    state = FocusState(
      initialDurationSeconds: seconds,
      durationLeftSeconds: seconds,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      linkedActivityId: state.linkedActivityId,
      currentSessionId: null,
      sessionType: 'Custom',
    );
  }

  void setLinkedActivity(String? activityId) {
    state = state.copyWith(linkedActivityId: activityId);
  }

  Future<void> startTimer() async {
    _ticker?.cancel();
    _sessionStartTime = DateTime.now();

    final authState = _ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    
    String? sessionId;
    if (user != null) {
      final newSession = FocusSessionModel(
        id: '',
        userId: user.uid,
        startTime: _sessionStartTime!,
        endTime: _sessionStartTime!, // initially same
        durationMinutes: 0, // initially 0
        sessionType: state.sessionType,
        completed: false,
        createdAt: DateTime.now(),
        activityId: state.linkedActivityId,
      );
      try {
        sessionId = await _ref.read(focusRepositoryProvider).createSession(newSession);
      } catch (_) {
        // Fallback or handle error silently
      }
    }

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isCompleted: false,
      currentSessionId: sessionId,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.durationLeftSeconds > 1) {
        state = state.copyWith(
          durationLeftSeconds: state.durationLeftSeconds - 1,
        );
      } else {
        _handleCompletion();
      }
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      isRunning: false,
      isPaused: true,
    );
  }

  void resumeTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.durationLeftSeconds > 1) {
        state = state.copyWith(
          durationLeftSeconds: state.durationLeftSeconds - 1,
        );
      } else {
        _handleCompletion();
      }
    });
  }

  Future<void> stopTimer() async {
    _ticker?.cancel();
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    
    if (user != null && state.currentSessionId != null) {
      final now = DateTime.now();
      final elapsedSeconds = state.initialDurationSeconds - state.durationLeftSeconds;
      final elapsedMinutes = elapsedSeconds ~/ 60;
      
      try {
        await _ref.read(focusRepositoryProvider).endSession(
          state.currentSessionId!,
          completed: false,
          endTime: now,
          durationMinutes: elapsedMinutes,
        );
        // Refresh analytics and streaks even if not fully completed,
        // but only completed sessions affect active streaks as per rule.
        await _ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(user.uid);
        await _ref.read(streakRepositoryProvider).calculateStreakFromActivities(user.uid);
      } catch (_) {}
    }

    state = state.copyWith(
      durationLeftSeconds: state.initialDurationSeconds,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      currentSessionId: null,
    );
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null && state.currentSessionId != null) {
      try {
        await _ref.read(focusRepositoryProvider).deleteSession(state.currentSessionId!);
        await _ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(user.uid);
        await _ref.read(streakRepositoryProvider).calculateStreakFromActivities(user.uid);
      } catch (_) {}
    }

    state = state.copyWith(
      durationLeftSeconds: state.initialDurationSeconds,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      currentSessionId: null,
    );
  }

  Future<void> saveSession() async {
    await _handleCompletion();
  }

  Future<void> _handleCompletion() async {
    _ticker?.cancel();
    final end = DateTime.now();
    
    state = state.copyWith(
      durationLeftSeconds: 0,
      isRunning: false,
      isPaused: false,
      isCompleted: true,
    );

    final user = _ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user != null && state.currentSessionId != null) {
      final elapsedMinutes = state.initialDurationSeconds ~/ 60;
      try {
        await _ref.read(focusRepositoryProvider).endSession(
          state.currentSessionId!,
          completed: true,
          endTime: end,
          durationMinutes: elapsedMinutes,
        );
        
        // Recalculate streaks and analytics
        await _ref.read(analyticsRepositoryProvider).calculateAndSaveAnalytics(user.uid);
        await _ref.read(streakRepositoryProvider).calculateStreakFromActivities(user.uid);
      } catch (_) {}
    }
  }

  void clearCompleted() {
    state = state.copyWith(
      isCompleted: false,
      durationLeftSeconds: state.initialDurationSeconds,
      currentSessionId: null,
    );
  }
}

final focusControllerProvider = StateNotifierProvider<FocusController, FocusState>((ref) {
  return FocusController(ref);
});
