// lib/features/streaks/presentation/screens/streaks_screen.dart
import 'package:flutter/material.dart';

class StreaksScreen extends StatelessWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks Engine'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 72,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Consistency & Badges Tracker',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Placeholder body for daily/weekly streaks statistics and achievements lists.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                      SizedBox(width: 12),
                      Text(
                        '0 Day Active Streak',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
