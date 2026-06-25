// lib/features/knowledge_vault/presentation/providers/knowledge_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/journal_model.dart';
import '../../domain/models/knowledge_item_model.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

// --- Notes Stream ---
final notesStreamProvider = StreamProvider<List<NoteModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(knowledgeRepositoryProvider);
  return repo.streamNotes(user.uid);
});

// --- Journals Stream ---
final journalsStreamProvider = StreamProvider<List<JournalModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(knowledgeRepositoryProvider);
  return repo.streamJournals(user.uid);
});

// --- Knowledge Items Stream ---
final knowledgeItemsStreamProvider = StreamProvider<List<KnowledgeItemModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(knowledgeRepositoryProvider);
  return repo.streamKnowledgeItems(user.uid);
});

// --- Journal Streak Calculation Provider ---
final journalStreakProvider = Provider<int>((ref) {
  final journalsAsync = ref.watch(journalsStreamProvider);
  final journals = journalsAsync.valueOrNull ?? [];
  if (journals.isEmpty) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // Extract unique sorted normalized entry dates
  final entryDates = journals
      .map((j) => DateTime(j.entryDate.year, j.entryDate.month, j.entryDate.day))
      .toSet()
      .toList();
  entryDates.sort((a, b) => b.compareTo(a)); // Descending sort

  if (entryDates.isEmpty) return 0;

  // Streak only continues if there is an entry today or yesterday
  final hasToday = entryDates.contains(today);
  final hasYesterday = entryDates.contains(yesterday);

  if (!hasToday && !hasYesterday) return 0;

  int streak = 0;
  DateTime checkDate = hasToday ? today : yesterday;

  while (entryDates.contains(checkDate)) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }

  return streak;
});

// --- Knowledge Controller for CRUD Actions ---
class KnowledgeController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  KnowledgeController(this._ref) : super(const AsyncValue.data(null));

  KnowledgeRepository get _repo => _ref.read(knowledgeRepositoryProvider);

  // --- Notes CRUD ---
  Future<void> addNote(NoteModel note) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createNote(note);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Note Created 📝',
        'New note "${note.title}" saved under category "${note.category}".',
        'General',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editNote(NoteModel note) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateNote(note);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Note Updated 📝',
        'Note "${note.title}" has been updated.',
        'General',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteNote(String id, String noteTitle) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteNote(id);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Note Deleted 🗑️',
        'Note "$noteTitle" was removed.',
        'General',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Journals CRUD ---
  Future<void> addJournal(JournalModel journal) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createJournal(journal);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Journal Logged 📔',
        'Logged reflection mood: ${journal.mood}. Keep writing to build a streak!',
        'Personal',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> editJournal(JournalModel journal) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateJournal(journal);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteJournal(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteJournal(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // --- Knowledge Items CRUD ---
  Future<void> addKnowledgeItem(KnowledgeItemModel item) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createKnowledgeItem(item);
      state = const AsyncValue.data(null);

      // Trigger notification
      await _ref.read(notificationControllerProvider.notifier).addGeneralNotification(
        'Quick Capture Saved ⚡',
        'Saved a new ${item.type.toLowerCase()}: "${item.content.length > 30 ? '${item.content.substring(0, 30)}...' : item.content}"',
        'General',
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteKnowledgeItem(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteKnowledgeItem(id);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final knowledgeControllerProvider =
    StateNotifierProvider<KnowledgeController, AsyncValue<void>>((ref) {
  return KnowledgeController(ref);
});
