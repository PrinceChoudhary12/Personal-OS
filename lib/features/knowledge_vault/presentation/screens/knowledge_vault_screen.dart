// lib/features/knowledge_vault/presentation/screens/knowledge_vault_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../student_hub/presentation/providers/student_providers.dart';
import '../providers/knowledge_providers.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/knowledge_item_model.dart';

class KnowledgeVaultScreen extends ConsumerStatefulWidget {
  const KnowledgeVaultScreen({super.key});

  @override
  ConsumerState<KnowledgeVaultScreen> createState() => _KnowledgeVaultScreenState();
}

class _KnowledgeVaultScreenState extends ConsumerState<KnowledgeVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filtering State
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';
  String? _selectedSubjectFilter;

  // Quick Capture Form State
  final _captureController = TextEditingController();
  String _selectedCaptureType = 'Idea'; // 'Idea', 'Task', 'Quote'
  final _captureFormKey = GlobalKey<FormState>();

  final List<String> _categories = [
    'All',
    'General',
    'Study Note',
    'Research',
    'Review',
    'Work',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to apply search query
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _captureController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickCapture() async {
    if (!_captureFormKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthStateProvider).valueOrNull;
    if (user == null) return;

    final item = KnowledgeItemModel(
      id: '',
      userId: user.uid,
      type: _selectedCaptureType,
      content: _captureController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(knowledgeControllerProvider.notifier).addKnowledgeItem(item);
    _captureController.clear();
  }

  Color _getCaptureColor(String type) {
    switch (type) {
      case 'Idea':
        return Colors.orangeAccent;
      case 'Task':
        return Colors.blueAccent;
      case 'Quote':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getCaptureIcon(String type) {
    switch (type) {
      case 'Idea':
        return Icons.lightbulb_outline_rounded;
      case 'Task':
        return Icons.check_circle_outline_rounded;
      case 'Quote':
        return Icons.format_quote_rounded;
      default:
        return Icons.star_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);
    final capturesAsync = ref.watch(knowledgeItemsStreamProvider);
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];
    final streak = ref.watch(journalStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledge Vault',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.6),
        ),
        centerTitle: false,
        actions: [
          // Journal Button with streak indicator
          TextButton.icon(
            onPressed: () => context.push('/knowledge-vault/journal'),
            icon: const Icon(Icons.book_outlined, size: 20, color: AppColors.primary),
            label: Text(
              'Journal (${streak}d 🔥)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Create Note',
            onPressed: () => context.push('/knowledge-vault/notes/create'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Notes & Study Guides'),
            Tab(text: 'Quick Capture Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Notes
          notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Error loading notes: $err')),
            data: (notes) {
              // Perform searches and filterings
              final query = _searchController.text.toLowerCase().trim();
              final filteredNotes = notes.where((note) {
                // Category match
                final matchesCategory = _selectedCategoryFilter == 'All' || note.category == _selectedCategoryFilter;

                // Subject match
                final matchesSubject = _selectedSubjectFilter == null || note.subject == _selectedSubjectFilter;

                // Text search match
                final matchesQuery = query.isEmpty ||
                    note.title.toLowerCase().contains(query) ||
                    note.content.toLowerCase().contains(query) ||
                    note.tags.any((t) => t.toLowerCase().contains(query));

                return matchesCategory && matchesSubject && matchesQuery;
              }).toList();

              return Column(
                children: [
                  _buildSearchAndFilters(subjects),
                  Expanded(child: _buildNotesList(filteredNotes, subjects)),
                ],
              );
            },
          ),

          // Tab 2: Quick Capture
          capturesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Error loading captures: $err')),
            data: (captures) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQuickCaptureForm(),
                        const SizedBox(height: 30),
                        const Text(
                          'Captured Items',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const Divider(height: 20),
                        _buildCapturesList(captures),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/knowledge-vault/notes/create');
          } else {
            // Focus on capture form if on Tab 2
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use the capture form at the top!')),
            );
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSearchAndFilters(List<dynamic> subjects) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search title, content, or tags...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Filters Row
          Row(
            children: [
              // Category filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategoryFilter = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Subject filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedSubjectFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter Course',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Courses', style: TextStyle(fontSize: 12))),
                    ...subjects.map((sub) {
                      return DropdownMenuItem<String?>(value: sub.id, child: Text(sub.name, style: const TextStyle(fontSize: 12)));
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSubjectFilter = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<NoteModel> notes, List<dynamic> subjects) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No notes found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search queries or create a new note.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final formattedDate = '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}';
        final linkedSubject = note.subject != null
            ? subjects.where((s) => s.id == note.subject).firstOrNull
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/knowledge-vault/notes/${note.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          note.category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    note.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (linkedSubject != null || note.tags.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        if (linkedSubject != null) ...[
                          const Icon(Icons.school_outlined, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            linkedSubject.name,
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (note.tags.isNotEmpty)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: note.tags.map((tag) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Text(
                                      '#$tag',
                                      style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickCaptureForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _captureFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quick Capture',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCaptureType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Idea', child: Text('Idea 💡')),
                        DropdownMenuItem(value: 'Task', child: Text('Task ✅')),
                        DropdownMenuItem(value: 'Quote', child: Text('Quote 💬')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCaptureType = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _captureController,
                      decoration: InputDecoration(
                        labelText: 'Capture detail...',
                        hintText: 'e.g. read chapter 5, "Live as if..."',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter some text' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveQuickCapture,
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Capture Item', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturesList(List<KnowledgeItemModel> captures) {
    if (captures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'No captures found. Try logging an idea or task!',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: captures.length,
      itemBuilder: (context, index) {
        final capture = captures[index];
        final color = _getCaptureColor(capture.type);
        final icon = _getCaptureIcon(capture.type);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              capture.content,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              capture.type,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => ref.read(knowledgeControllerProvider.notifier).deleteKnowledgeItem(capture.id),
            ),
          ),
        );
      },
    );
  }
}
