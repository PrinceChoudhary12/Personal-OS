// lib/features/knowledge_vault/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../student_hub/presentation/providers/student_providers.dart';
import '../providers/knowledge_providers.dart';
import '../../domain/models/note_model.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({required this.noteId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesStreamProvider).valueOrNull ?? [];
    final note = notes.where((n) => n.id == noteId).firstOrNull;
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note Details')),
        body: const Center(child: Text('Note not found')),
      );
    }

    final linkedSubject = note.subject != null
        ? subjects.where((s) => s.id == note.subject).firstOrNull
        : null;

    final formattedCreated = '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}';
    final formattedUpdated = '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Note',
            onPressed: () => context.push('/knowledge-vault/notes/edit/${note.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Note',
            onPressed: () => _confirmDelete(context, ref, note),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Subject info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        note.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (linkedSubject != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_outlined, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              linkedSubject.name,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Note Title
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Timestamps
                Text(
                  'Created: $formattedCreated  •  Last updated: $formattedUpdated',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 30),

                // Tags chips row
                if (note.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: note.tags.map((tag) {
                      return Chip(
                        label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Note Content Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete note "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await ref.read(knowledgeControllerProvider.notifier).deleteNote(note.id, note.title);
              if (context.mounted) {
                context.pop(); // Go back to vault list
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
