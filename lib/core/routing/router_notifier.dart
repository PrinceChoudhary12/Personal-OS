// lib/core/routing/router_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Temporary router notifier.
/// Firebase is not configured yet, so we bypass auth checks
/// and force Splash -> Login.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(
      firebaseAuthStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  /// Authentication state redirect logic.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(firebaseAuthStateProvider);

    // If the auth state is still loading, wait on splash
    if (authState.isLoading) {
      return '/splash';
    }

    final hasUser = authState.valueOrNull != null;
    final location = state.matchedLocation;
    final isGoingToAuth = location == '/login' || location == '/signup';
    final isGoingToSplash = location == '/splash';

    if (!hasUser) {
      // User is not signed in, force them to login if trying to access protected routes
      if (!isGoingToAuth && !isGoingToSplash) {
        return '/login';
      }
    } else {
      // User is signed in, prevent them from going back to auth or splash screens
      if (isGoingToAuth || isGoingToSplash) {
        return '/dashboard';
      }
    }

    // Allow navigation
    return null;
  }
}

/// Provider for RouterNotifier
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});