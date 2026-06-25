// test/features/knowledge_vault/knowledge_vault_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/knowledge_vault/domain/models/note_model.dart';
import 'package:personal_os/features/knowledge_vault/domain/models/journal_model.dart';
import 'package:personal_os/features/knowledge_vault/domain/models/knowledge_item_model.dart';

void main() {
  group('NoteModel Serialization Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'note_1',
        userId: 'user_1',
        title: 'Algorithms and Complexity',
        content: 'Big O notation defines upper bound...',
        subject: 'subject_123',
        tags: ['academic', 'computer_science'],
        category: 'Study Note',
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();
      expect(map['title'], 'Algorithms and Complexity');
      expect(map['category'], 'Study Note');
      expect(map['subject'], 'subject_123');
      expect((map['tags'] as List<String>).contains('academic'), true);

      final fromMap = NoteModel.fromMap(map, 'note_1');
      expect(fromMap.id, 'note_1');
      expect(fromMap.title, 'Algorithms and Complexity');
      expect(fromMap.subject, 'subject_123');
      expect(fromMap.tags.length, 2);
      expect(fromMap.category, 'Study Note');
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'note_1',
        userId: 'user_1',
        title: 'Algorithms',
        content: 'Detail',
        tags: [],
        category: 'General',
        createdAt: now,
        updatedAt: now,
      );

      final copy = note.copyWith(title: 'Data Structures', category: 'Study Note');
      expect(copy.id, 'note_1');
      expect(copy.title, 'Data Structures');
      expect(copy.category, 'Study Note');
    });
  });

  group('JournalModel Serialization & Streak Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final journal = JournalModel(
        id: 'journal_1',
        userId: 'user_1',
        content: 'Felt very productive today!',
        mood: 'Productive',
        reflection: 'Need to sleep early.',
        entryDate: now,
        createdAt: now,
      );

      final map = journal.toMap();
      expect(map['mood'], 'Productive');
      expect(map['reflection'], 'Need to sleep early.');

      final fromMap = JournalModel.fromMap(map, 'journal_1');
      expect(fromMap.id, 'journal_1');
      expect(fromMap.mood, 'Productive');
      expect(fromMap.content, 'Felt very productive today!');
    });

    test('Streak calculation logic mock test', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));
      final randomDay = today.subtract(const Duration(days: 4)); // gap!

      final entries = [
        JournalModel(
          id: '1',
          userId: 'user_1',
          content: 'Today',
          mood: 'Calm',
          reflection: '',
          entryDate: today,
          createdAt: now,
        ),
        JournalModel(
          id: '2',
          userId: 'user_1',
          content: 'Yesterday',
          mood: 'Calm',
          reflection: '',
          entryDate: yesterday,
          createdAt: now,
        ),
        JournalModel(
          id: '3',
          userId: 'user_1',
          content: 'Day Before',
          mood: 'Calm',
          reflection: '',
          entryDate: dayBefore,
          createdAt: now,
        ),
        JournalModel(
          id: '4',
          userId: 'user_1',
          content: 'Gap day',
          mood: 'Calm',
          reflection: '',
          entryDate: randomDay,
          createdAt: now,
        ),
      ];

      // Replicating streak logic
      final entryDates = entries
          .map((j) => DateTime(j.entryDate.year, j.entryDate.month, j.entryDate.day))
          .toSet()
          .toList();
      entryDates.sort((a, b) => b.compareTo(a));

      final hasToday = entryDates.contains(today);
      final hasYesterday = entryDates.contains(yesterday);

      int streak = 0;
      if (hasToday || hasYesterday) {
        DateTime checkDate = hasToday ? today : yesterday;
        while (entryDates.contains(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }

      expect(streak, 3);
    });
  });

  group('KnowledgeItemModel Serialization Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final item = KnowledgeItemModel(
        id: 'capture_1',
        userId: 'user_1',
        type: 'Quote',
        content: 'Stay hungry, stay foolish.',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['type'], 'Quote');
      expect(map['content'], 'Stay hungry, stay foolish.');

      final fromMap = KnowledgeItemModel.fromMap(map, 'capture_1');
      expect(fromMap.id, 'capture_1');
      expect(fromMap.type, 'Quote');
      expect(fromMap.content, 'Stay hungry, stay foolish.');
    });
  });
}
