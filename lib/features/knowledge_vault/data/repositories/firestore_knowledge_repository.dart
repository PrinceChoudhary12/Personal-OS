// lib/features/knowledge_vault/data/repositories/firestore_knowledge_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/journal_model.dart';
import '../../domain/models/knowledge_item_model.dart';
import '../../domain/repositories/knowledge_repository.dart';

class FirestoreKnowledgeRepository implements KnowledgeRepository {
  final FirebaseFirestore _firestore;

  FirestoreKnowledgeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _firestore.collection('notes');

  CollectionReference<Map<String, dynamic>> get _journalsCol =>
      _firestore.collection('journals');

  CollectionReference<Map<String, dynamic>> get _knowledgeItemsCol =>
      _firestore.collection('knowledge_items');

  // --- Notes Operations ---

  @override
  Stream<List<NoteModel>> streamNotes(String userId) {
    return _notesCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by updatedAt descending
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Future<List<NoteModel>> getNotes(String userId) async {
    try {
      final snapshot = await _notesCol.where('userId', isEqualTo: userId).get();
      final list = snapshot.docs
          .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final doc = await _notesCol.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return NoteModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createNote(NoteModel note) async {
    try {
      final docRef = note.id.isEmpty ? _notesCol.doc() : _notesCol.doc(note.id);
      final toSave = note.id.isEmpty ? note.copyWith(id: docRef.id) : note;
      await docRef.set(toSave.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await _notesCol.doc(note.id).set(note.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await _notesCol.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }

  // --- Journal Operations ---

  @override
  Stream<List<JournalModel>> streamJournals(String userId) {
    return _journalsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => JournalModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by entryDate descending
      list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      return list;
    });
  }

  @override
  Future<List<JournalModel>> getJournals(String userId) async {
    try {
      final snapshot = await _journalsCol.where('userId', isEqualTo: userId).get();
      final list = snapshot.docs
          .map((doc) => JournalModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createJournal(JournalModel journal) async {
    try {
      final docRef = journal.id.isEmpty ? _journalsCol.doc() : _journalsCol.doc(journal.id);
      final toSave = journal.id.isEmpty ? journal.copyWith(id: docRef.id) : journal;
      await docRef.set(toSave.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateJournal(JournalModel journal) async {
    try {
      await _journalsCol.doc(journal.id).set(journal.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteJournal(String id) async {
    try {
      await _journalsCol.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }

  // --- Knowledge Items Operations ---

  @override
  Stream<List<KnowledgeItemModel>> streamKnowledgeItems(String userId) {
    return _knowledgeItemsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => KnowledgeItemModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<KnowledgeItemModel>> getKnowledgeItems(String userId) async {
    try {
      final snapshot = await _knowledgeItemsCol.where('userId', isEqualTo: userId).get();
      final list = snapshot.docs
          .map((doc) => KnowledgeItemModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> createKnowledgeItem(KnowledgeItemModel item) async {
    try {
      final docRef = item.id.isEmpty ? _knowledgeItemsCol.doc() : _knowledgeItemsCol.doc(item.id);
      final toSave = item.id.isEmpty ? item.copyWith(id: docRef.id) : item;
      await docRef.set(toSave.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> updateKnowledgeItem(KnowledgeItemModel item) async {
    try {
      await _knowledgeItemsCol.doc(item.id).set(item.toMap(), SetOptions(merge: true));
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteKnowledgeItem(String id) async {
    try {
      await _knowledgeItemsCol.doc(id).delete();
    } catch (_) {
      rethrow;
    }
  }
}
