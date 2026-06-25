// lib/features/knowledge_vault/presentation/screens/create_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../student_hub/presentation/providers/student_providers.dart';
import '../providers/knowledge_providers.dart';
import '../../domain/models/note_model.dart';

class CreateEditNoteScreen extends ConsumerStatefulWidget {
  final String? editNoteId;

  const CreateEditNoteScreen({this.editNoteId, super.key});

  @override
  ConsumerState<CreateEditNoteScreen> createState() => _CreateEditNoteScreenState();
}

class _CreateEditNoteScreenState extends ConsumerState<CreateEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'General';
  String? _selectedSubjectId;
  bool _isInit = false;
  NoteModel? _existingNote;

  final List<String> _categories = [
    'General',
    'Study Note',
    'Research',
    'Review',
    'Work',
    'Personal',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    // Parse comma separated tags
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final now = DateTime.now();

    final note = NoteModel(
      id: widget.editNoteId ?? '',
      userId: user.uid,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      subject: _selectedSubjectId,
      tags: tags,
      category: _selectedCategory,
      createdAt: _existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.editNoteId != null) {
      await ref.read(knowledgeControllerProvider.notifier).editNote(note);
    } else {
      await ref.read(knowledgeControllerProvider.notifier).addNote(note);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesStreamProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

    if (widget.editNoteId != null && !_isInit) {
      _existingNote = notes.where((n) => n.id == widget.editNoteId).firstOrNull;
      if (_existingNote != null) {
        _titleController.text = _existingNote!.title;
        _contentController.text = _existingNote!.content;
        _tagsController.text = _existingNote!.tags.join(', ');
        _selectedCategory = _existingNote!.category;
        _selectedSubjectId = _existingNote!.subject;
      }
      _isInit = true;
    }

    final isSaving = ref.watch(knowledgeControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editNoteId != null ? 'Edit Note' : 'Create Note'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Lecture on Data Structures',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter note title' : null,
                  ),
                  const SizedBox(height: 20),

                  // Category Selector Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : 'General',
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Subject Selector (Optional)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Link to Course / Subject (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None / General')),
                      ...subjects.map((sub) {
                        return DropdownMenuItem<String?>(value: sub.id, child: Text(sub.name));
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g., flutter, firestore, algorithms',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Body
                  TextFormField(
                    controller: _contentController,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      hintText: 'Start writing your note content here...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter note content' : null,
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    onPressed: isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.editNoteId != null ? 'Save Changes' : 'Create Note',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
