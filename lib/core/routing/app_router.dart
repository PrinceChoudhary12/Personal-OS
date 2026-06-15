// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/focus_timer/presentation/screens/focus_timer_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/goals/presentation/screens/create_edit_goal_screen.dart';
import '../../features/streaks/presentation/screens/streaks_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/activities/presentation/screens/activity_detail_screen.dart';
import '../../features/activities/presentation/screens/create_edit_activity_screen.dart';
import 'navigation_scaffold.dart';
import 'router_notifier.dart';

final _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter is exposed as a Riverpod [Provider] so that [RouterNotifier]
/// (which depends on Riverpod) can be wired in cleanly.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Splash ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      // ── Profile ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // ── Settings ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // ── Activities Extra ─────────────────────────────────────────────────
      GoRoute(
        path: '/activity/create',
        builder: (context, state) => const CreateEditActivityScreen(),
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ActivityDetailScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/activity/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateEditActivityScreen(editActivityId: id);
        },
      ),
      GoRoute(
        path: '/goals/create',
        builder: (context, state) => const CreateEditGoalScreen(),
      ),
      GoRoute(
        path: '/goals/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateEditGoalScreen(editGoalId: id);
        },
      ),
      // ── Protected Shell (bottom nav tabs) ─────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/activities',
            builder: (context, state) => const ActivitiesScreen(),
          ),
          GoRoute(
            path: '/timer',
            builder: (context, state) => const FocusTimerScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/streaks',
            builder: (context, state) => const StreaksScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
});
