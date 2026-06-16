// lib/features/analytics/presentation/providers/analytics_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/analytics_model.dart';

// --- Stream of AnalyticsSnapshot for the current user ---
final analyticsStreamProvider = StreamProvider<AnalyticsModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.streamAnalytics(user.uid);
});

// --- Daily Productivity Provider (7 days list) ---
final dailyAnalyticsProvider = Provider<List<double>>((ref) {
  final analytics = ref.watch(analyticsStreamProvider).valueOrNull;
  return analytics?.dailyProductivity ?? List.filled(7, 0.0);
});

// --- Weekly Productivity Provider (4 weeks list) ---
final weeklyAnalyticsProvider = Provider<List<double>>((ref) {
  final analytics = ref.watch(analyticsStreamProvider).valueOrNull;
  return analytics?.weeklyProductivity ?? List.filled(4, 0.0);
});

// --- Monthly Productivity Provider (6 months list) ---
final monthlyAnalyticsProvider = Provider<List<double>>((ref) {
  final analytics = ref.watch(analyticsStreamProvider).valueOrNull;
  return analytics?.monthlyProductivity ?? List.filled(6, 0.0);
});

// --- Goal Analytics Provider (Goal Completion Rate) ---
final goalAnalyticsProvider = Provider<double>((ref) {
  final analytics = ref.watch(analyticsStreamProvider).valueOrNull;
  return analytics?.goalCompletionRate ?? 0.0;
});

// --- Dashboard Analytics Provider (Combined Card Stats) ---
final dashboardAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final analytics = ref.watch(analyticsStreamProvider).valueOrNull;
  return {
    'totalActivities': analytics?.totalActivities ?? 0,
    'totalFocusTime': analytics?.totalFocusTime ?? 0,
    'averageSessionDuration': analytics?.averageSessionDuration ?? 0.0,
    'goalCompletionRate': analytics?.goalCompletionRate ?? 0.0,
    'categoryBreakdown': analytics?.categoryBreakdown ?? const <String, int>{},
  };
});

// --- Controller to trigger analytics calculations manually ---
final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, void>(AnalyticsController.new);

class AnalyticsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> syncAnalytics() async {
    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return false;
    state = const AsyncLoading();
    try {
      final repo = ref.read(analyticsRepositoryProvider);
      await repo.calculateAndSaveAnalytics(user.uid);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
