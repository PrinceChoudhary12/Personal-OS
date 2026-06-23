// lib/features/habits/data/repositories/firestore_habit_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/habit_model.dart';
import '../../domain/repositories/habit_repository.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;

  FirestoreHabitRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('habits');

  @override
  Stream<List<HabitModel>> streamHabits(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> createHabit(HabitModel habit) async {
    final docRef = habit.id.isEmpty ? _collection.doc() : _collection.doc(habit.id);
    final toSave = habit.id.isEmpty ? habit.copyWith(id: docRef.id) : habit;
    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await _collection.doc(habit.id).set(habit.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> toggleHabitCompletion(String habitId, String dateStr) async {
    final docRef = _collection.doc(habitId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final habit = HabitModel.fromMap(data, snapshot.id);
      final List<String> updatedDates = List<String>.from(habit.completedDates);
      if (updatedDates.contains(dateStr)) {
        updatedDates.remove(dateStr);
      } else {
        updatedDates.add(dateStr);
      }

      transaction.update(docRef, {
        'completedDates': updatedDates,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }
}
