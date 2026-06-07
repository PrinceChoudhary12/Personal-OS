// lib/features/splash/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';

/// The splash screen simply listens to [firebaseAuthStateProvider].
/// The RouterNotifier redirect handles the actual navigation once
/// auth state resolves — so this screen only needs to display the brand.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger a rebuild if auth state changes. RouterNotifier's redirect
    // will handle the page navigation automatically.
    ref.watch(firebaseAuthStateProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.blur_on_rounded,
                size: 56,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'PERSONAL OS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: const Color(0xFF6366F1),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your productive life, centralized.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 56),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
