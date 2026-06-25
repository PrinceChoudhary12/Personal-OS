// lib/features/knowledge_vault/presentation/screens/journal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/knowledge_providers.dart';
import '../../domain/models/journal_model.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _reflectionController = TextEditingController();

  String _selectedMood = 'Calm';
  bool _isInit = false;
  JournalModel? _todayJournal;

  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Productive': '💪',
    'Stressed': '🤯',
    'Calm': '😌',
    'Tired': '😴',
  };

  @override
  void dispose() {
    _contentController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final journal = JournalModel(
      id: _todayJournal?.id ?? '',
      userId: user.uid,
      content: _contentController.text.trim(),
      mood: _selectedMood,
      reflection: _reflectionController.text.trim(),
      entryDate: _todayJournal?.entryDate ?? today,
      createdAt: _todayJournal?.createdAt ?? now,
    );

    if (_todayJournal != null) {
      await ref.read(knowledgeControllerProvider.notifier).editJournal(journal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today\'s journal entry updated!')),
        );
      }
    } else {
      await ref.read(knowledgeControllerProvider.notifier).addJournal(journal);
      _contentController.clear();
      _reflectionController.clear();
      setState(() {
        _selectedMood = 'Calm';
        _todayJournal = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journals = ref.watch(journalsStreamProvider).valueOrNull ?? [];
    final streak = ref.watch(journalStreakProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!_isInit && journals.isNotEmpty) {
      _todayJournal = journals.where((j) {
        final d = j.entryDate;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).firstOrNull;

      if (_todayJournal != null) {
        _contentController.text = _todayJournal!.content;
        _reflectionController.text = _todayJournal!.reflection;
        _selectedMood = _todayJournal!.mood;
      }
      _isInit = true;
    }

    final isSaving = ref.watch(knowledgeControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Journal & Reflections'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Streak Card & Status
                _buildStreakCard(streak),
                const SizedBox(height: 24),

                // Journal Entry Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _todayJournal != null
                                ? 'Update Today\'s Journal Entry'
                                : 'How was your day? Log Entry',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const Divider(height: 24),

                          // Mood Select
                          const Text(
                            'Select your mood today:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _moodEmojis.keys.map((mood) {
                              final emoji = _moodEmojis[mood]!;
                              final isSelected = _selectedMood == mood;
                              return ChoiceChip(
                                label: Text('$emoji $mood'),
                                selected: isSelected,
                                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedMood = mood;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Today's notes / tasks / ideas content
                          TextFormField(
                            controller: _contentController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Reflection Notes / Accomplishments',
                              hintText: 'What did you achieve today? What went well?',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Please enter some reflection notes' : null,
                          ),
                          const SizedBox(height: 16),

                          // Reflection Text
                          TextFormField(
                            controller: _reflectionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Daily Reflection / Thoughts (Optional)',
                              hintText: 'Any learnings or thoughts for self-improvement...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _todayJournal != null ? 'Update Entry' : 'Log Today\'s Journal',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Journal History
                const Text(
                  'Journal History',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Divider(height: 20),
                if (journals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No historical entries found. Log your first journal above!',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: journals.length,
                    itemBuilder: (context, index) {
                      final item = journals[index];
                      final dateStr = '${item.entryDate.day}/${item.entryDate.month}/${item.entryDate.year}';
                      final emoji = _moodEmojis[item.mood] ?? '😌';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(
                            'Mood: ${item.mood} ($dateStr)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            item.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notes & Accomplishments:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.content, style: const TextStyle(fontSize: 14)),
                                  if (item.reflection.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Daily Reflection / Thoughts:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.reflection, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            )
                          ],
                        ),
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

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 24,
            child: Text('🔥', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day${streak == 1 ? '' : 's'} Reflection Streak',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Write reflections daily to build self-awareness and maintain your habits.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
