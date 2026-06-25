// lib/features/knowledge_vault/domain/repositories/knowledge_repository.dart

import '../models/note_model.dart';
import '../models/journal_model.dart';
import '../models/knowledge_item_model.dart';

abstract class KnowledgeRepository {
  // Notes operations
  Stream<List<NoteModel>> streamNotes(String userId);
  Future<List<NoteModel>> getNotes(String userId);
  Future<NoteModel?> getNoteById(String id);
  Future<void> createNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String id);

  // Journal operations
  Stream<List<JournalModel>> streamJournals(String userId);
  Future<List<JournalModel>> getJournals(String userId);
  Future<void> createJournal(JournalModel journal);
  Future<void> updateJournal(JournalModel journal);
  Future<void> deleteJournal(String id);

  // Knowledge Items (Quick Capture) operations
  Stream<List<KnowledgeItemModel>> streamKnowledgeItems(String userId);
  Future<List<KnowledgeItemModel>> getKnowledgeItems(String userId);
  Future<void> createKnowledgeItem(KnowledgeItemModel item);
  Future<void> updateKnowledgeItem(KnowledgeItemModel item);
  Future<void> deleteKnowledgeItem(String id);
}
