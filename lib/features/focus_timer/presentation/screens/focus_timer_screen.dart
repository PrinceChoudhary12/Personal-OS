// lib/features/focus_timer/presentation/screens/focus_timer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../providers/focus_session_providers.dart';
import '../providers/timer_notifier.dart';

class FocusTimerScreen extends ConsumerWidget {
  const FocusTimerScreen({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerNotifierProvider);
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);

    // Auto-trigger completion dialog
    if (timerState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 28),
                SizedBox(width: 8),
                Text('Great Job! 🎉'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You have successfully completed your focus session.'),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${timerState.initialDurationSeconds ~/ 60} minutes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Your session has been logged in Firestore.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  timerNotifier.clearCompleted();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Timer'),
              ),
            ],
          ),
        );
      });
    }

    final double progressPercent = timerState.initialDurationSeconds > 0
        ? (timerState.durationLeftSeconds / timerState.initialDurationSeconds)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Timer Clock Container ---
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        // Countdown Ticker Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: progressPercent,
                                strokeWidth: 10,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                color: AppColors.primary,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(timerState.durationLeftSeconds),
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontSize: 54,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timerState.isRunning ? 'FOCUSING' : (timerState.isPaused ? 'PAUSED' : 'READY'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    color: timerState.isRunning ? AppColors.primary : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Preset Toggles
                        if (!timerState.isRunning && !timerState.isPaused) ...[
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _PresetButton(
                                label: '10s Test',
                                seconds: 10,
                                isSelected: timerState.initialDurationSeconds == 10,
                                onSelect: () => timerNotifier.setCustomDurationSeconds(10),
                              ),
                              _PresetButton(
                                label: '25m',
                                seconds: 25 * 60,
                                isSelected: timerState.initialDurationSeconds == 25 * 60,
                                onSelect: () => timerNotifier.setPreset(25),
                              ),
                              _PresetButton(
                                label: '45m',
                                seconds: 45 * 60,
                                isSelected: timerState.initialDurationSeconds == 45 * 60,
                                onSelect: () => timerNotifier.setPreset(45),
                              ),
                              _PresetButton(
                                label: '60m',
                                seconds: 60 * 60,
                                isSelected: timerState.initialDurationSeconds == 60 * 60,
                                onSelect: () => timerNotifier.setPreset(60),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!timerState.isRunning && !timerState.isPaused)
                              ElevatedButton.icon(
                                onPressed: timerNotifier.startTimer,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Session'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            if (timerState.isRunning) ...[
                              ElevatedButton.icon(
                                onPressed: timerNotifier.pauseTimer,
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('Pause'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.resetTimer,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                            if (timerState.isPaused) ...[
                              ElevatedButton.icon(
                                onPressed: timerNotifier.resumeTimer,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Resume'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.resetTimer,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Task Link Option ---
                activitiesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (activitiesList) {
                    if (activitiesList.isEmpty) return const SizedBox.shrink();
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Link to Activity',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DropdownButton<String?>(
                              value: timerState.linkedActivityId,
                              hint: const Text('Select Activity'),
                              onChanged: timerState.isRunning || timerState.isPaused
                                  ? null
                                  : (val) {
                                      timerNotifier.setLinkedActivity(val);
                                    },
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...activitiesList.map((a) {
                                  return DropdownMenuItem<String?>(
                                    value: a.id,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 150),
                                      child: Text(
                                        a.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- History Header ---
                Text(
                  'Focus History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // --- Recent focus sessions completed ---
                sessionsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Text('Error loading history: $err'),
                  data: (sessionsList) {
                    if (sessionsList.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No focus sessions logged yet. Complete a Pomodoro session to log focus hours!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessionsList.length,
                      itemBuilder: (context, index) {
                        final session = sessionsList[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              child: const Icon(Icons.timer, color: Colors.red),
                            ),
                            title: Text(
                              '${session.durationMinutes} Minutes Focused',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Started at ${_formatDateTime(session.startTime)} • ${session.outcomeStatus}',
                            ),
                            trailing: Text(
                              '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PresetButton({
    required this.label,
    required this.seconds,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}
