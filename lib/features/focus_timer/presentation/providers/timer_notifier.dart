// lib/features/focus_timer/presentation/providers/timer_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/focus_session_model.dart';
import 'focus_session_providers.dart';

class TimerState {
  final int initialDurationSeconds;
  final int durationLeftSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;
  final String? linkedActivityId;

  const TimerState({
    required this.initialDurationSeconds,
    required this.durationLeftSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.isCompleted,
    this.linkedActivityId,
  });

  TimerState copyWith({
    int? initialDurationSeconds,
    int? durationLeftSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isCompleted,
    String? linkedActivityId,
  }) {
    return TimerState(
      initialDurationSeconds: initialDurationSeconds ?? this.initialDurationSeconds,
      durationLeftSeconds: durationLeftSeconds ?? this.durationLeftSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  final Ref _ref;
  Timer? _ticker;
  DateTime? _sessionStartTime;

  TimerNotifier(this._ref)
      : super(const TimerState(
          initialDurationSeconds: 25 * 60,
          durationLeftSeconds: 25 * 60,
          isRunning: false,
          isPaused: false,
          isCompleted: false,
          linkedActivityId: null,
        ));

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void setPreset(int minutes) {
    _ticker?.cancel();
    state = TimerState(
      initialDurationSeconds: minutes * 60,
      durationLeftSeconds: minutes * 60,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      linkedActivityId: state.linkedActivityId,
    );
  }

  void setCustomDurationSeconds(int seconds) {
    _ticker?.cancel();
    state = TimerState(
      initialDurationSeconds: seconds,
      durationLeftSeconds: seconds,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      linkedActivityId: state.linkedActivityId,
    );
  }

  void setLinkedActivity(String? activityId) {
    state = state.copyWith(linkedActivityId: activityId);
  }

  void startTimer() {
    _ticker?.cancel();
    _sessionStartTime = DateTime.now();
    
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isCompleted: false,
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

  void resetTimer() {
    _ticker?.cancel();
    _sessionStartTime = null;
    state = state.copyWith(
      durationLeftSeconds: state.initialDurationSeconds,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
    );
  }

  Future<void> _handleCompletion() async {
    _ticker?.cancel();
    final start = _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: state.initialDurationSeconds));
    final end = DateTime.now();
    
    state = state.copyWith(
      durationLeftSeconds: 0,
      isRunning: false,
      isPaused: false,
      isCompleted: true,
    );

    final authState = _ref.read(firebaseAuthStateProvider);
    final user = authState.valueOrNull;
    if (user != null) {
      final session = FocusSessionModel(
        id: '',
        userId: user.uid,
        activityId: state.linkedActivityId,
        durationMinutes: (state.initialDurationSeconds) ~/ 60,
        startTime: start,
        endTime: end,
        outcomeStatus: 'Completed',
      );
      
      try {
        await _ref.read(focusSessionRepositoryProvider).logFocusSession(session);
      } catch (_) {
        // Silent catch for background failures, can display error states if necessary.
      }
    }
  }

  void clearCompleted() {
    state = state.copyWith(
      isCompleted: false,
      durationLeftSeconds: state.initialDurationSeconds,
    );
  }
}

final timerNotifierProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});
