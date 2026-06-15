// lib/core/routing/router_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(
      firebaseAuthStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(firebaseAuthStateProvider);

    final location = state.matchedLocation;

    debugPrint('Current Route: $location');
    debugPrint('User: ${authState.valueOrNull?.email}');
    debugPrint('Loading: ${authState.isLoading}');

    // Wait for Firebase auth initialization
    if (authState.isLoading) {
      if (location != '/splash') {
        return '/splash';
      }
      return null;
    }

    final loggedIn = authState.valueOrNull != null;

    // User NOT logged in
    if (!loggedIn) {
      final isAuthPage =
          location == '/login' ||
          location == '/signup' ||
          location == '/splash';

      if (!isAuthPage) {
        return '/login';
      }

      if (location == '/splash') {
        return '/login';
      }

      return null;
    }

    // User logged in
    if (loggedIn) {
      if (location == '/login' ||
          location == '/signup' ||
          location == '/splash') {
        return '/dashboard';
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});