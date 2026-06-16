// lib/features/focus_timer/presentation/screens/focus_timer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../domain/models/focus_session_model.dart';
import '../providers/focus_providers.dart';
import '../providers/focus_controller.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with SingleTickerProviderStateMixin {
  late TabController _historyTabController;

  @override
  void initState() {
    super.initState();
    _historyTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _historyTabController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showCustomDurationDialog(BuildContext context, FocusController controller) {
    final textController = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Focus Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration in minutes (1 - 180):'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'mins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final mins = int.tryParse(textController.text) ?? 30;
              if (mins > 0 && mins <= 180) {
                controller.setCustomDurationSeconds(mins * 60);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Timer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(focusControllerProvider);
    final timerNotifier = ref.read(focusControllerProvider.notifier);
    
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
                Text(
                  'Session Type: ${timerState.sessionType}',
                  style: const TextStyle(color: Colors.grey),
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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Timer Clock Card ---
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
                                const SizedBox(height: 2),
                                Text(
                                  'Type: ${timerState.sessionType}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Preset Options
                        if (!timerState.isRunning && !timerState.isPaused) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('25m Pomodoro'),
                                selected: timerState.initialDurationSeconds == 25 * 60 && timerState.sessionType == 'Pomodoro',
                                onSelected: (_) => timerNotifier.setPreset(25, 'Pomodoro'),
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('50m Deep Work'),
                                selected: timerState.initialDurationSeconds == 50 * 60 && timerState.sessionType == 'Deep Work',
                                onSelected: (_) => timerNotifier.setPreset(50, 'Deep Work'),
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Custom'),
                                selected: timerState.sessionType == 'Custom',
                                onSelected: (_) => _showCustomDurationDialog(context, timerNotifier),
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!timerState.isRunning && !timerState.isPaused)
                              ElevatedButton.icon(
                                onPressed: timerNotifier.startTimer,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Timer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.stopTimer,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Stop'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.resetTimer,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.stopTimer,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Stop'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: timerNotifier.resetTimer,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                // --- History and Statistics Section ---
                sessionsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Text('Error loading history: $err'),
                  data: (sessionsList) {
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    final weekStart = now.subtract(Duration(days: now.weekday - 1));
                    final weekStartStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

                    final todaySessions = sessionsList.where((s) => s.startTime.isAfter(todayStart)).toList();
                    final weeklySessions = sessionsList.where((s) => s.startTime.isAfter(weekStartStart)).toList();

                    final totalFocusMinutes = sessionsList.where((s) => s.completed).fold<int>(0, (sum, s) => sum + s.durationMinutes);
                    final todayFocusMinutes = todaySessions.where((s) => s.completed).fold<int>(0, (sum, s) => sum + s.durationMinutes);
                    final weeklyFocusMinutes = weeklySessions.where((s) => s.completed).fold<int>(0, (sum, s) => sum + s.durationMinutes);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Metric Cards ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricMiniCard(
                                title: "Today's Focus",
                                value: "$todayFocusMinutes min",
                                icon: Icons.today,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricMiniCard(
                                title: "This Week",
                                value: "${(weeklyFocusMinutes / 60.0).toStringAsFixed(1)} hrs",
                                icon: Icons.date_range,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricMiniCard(
                                title: "Total Focus",
                                value: "$totalFocusMinutes min",
                                icon: Icons.hourglass_empty,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Session History Tabs ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Session History',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        TabBar(
                          controller: _historyTabController,
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: "Today's Sessions"),
                            Tab(text: "Weekly Sessions"),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _historyTabController,
                            children: [
                              _buildSessionList(context, todaySessions),
                              _buildSessionList(context, weeklySessions),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildMetricMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 16,
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, List<FocusSessionModel> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          'No focus sessions in this period.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        final outcomeText = s.completed ? 'Completed' : 'Interrupted';
        final outcomeColor = s.completed ? Colors.green : Colors.red;
        final icon = s.completed ? Icons.check_circle_rounded : Icons.cancel_rounded;

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
              backgroundColor: outcomeColor.withValues(alpha: 0.1),
              child: Icon(Icons.timer, color: outcomeColor),
            ),
            title: Text(
              '${s.durationMinutes} Minutes Focused (${s.sessionType})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Started at ${_formatDateTime(s.startTime)} • $outcomeText',
              style: TextStyle(color: outcomeColor),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(icon, color: outcomeColor, size: 18),
                const SizedBox(height: 4),
                Text(
                  _formatDate(s.startTime),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
