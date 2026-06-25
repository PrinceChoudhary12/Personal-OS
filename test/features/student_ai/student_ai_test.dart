// test/features/student_ai/student_ai_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_os/features/student_ai/domain/models/chat_message_model.dart';
import 'package:personal_os/features/student_ai/data/repositories/firestore_student_ai_repository.dart';

// --- Fake Firestore Implementation to isolate repository logic without DB ---

class FakeDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  @override
  final String id;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  DocumentReference<Map<String, dynamic>> get reference => FakeDocumentReference([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery implements Query<Map<String, dynamic>> {
  final List<Map<String, dynamic>> dataList;
  FakeQuery(this.dataList);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeQuerySnapshot(
      dataList.map((d) => FakeDocumentSnapshot('doc_id', d)).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final List<Map<String, dynamic>> dataList;
  FakeCollectionReference(this.dataList);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return FakeQuery(dataList);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return FakeQuery(dataList);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeQuerySnapshot(
      dataList.map((d) => FakeDocumentSnapshot('doc_id', d)).toList(),
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(dataList);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    dataList.add(data);
    return FakeDocumentReference(dataList);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final List<Map<String, dynamic>> dataList;
  FakeDocumentReference(this.dataList);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference(dataList);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    dataList.add(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWriteBatch implements WriteBatch {
  @override
  void delete(DocumentReference document) {}

  @override
  Future<void> commit() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, List<Map<String, dynamic>>> collections;
  FakeFirebaseFirestore(this.collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference(collections[path] ?? []);
  }

  @override
  WriteBatch batch() => FakeWriteBatch();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChatMessageModel Serialization & Copying Tests', () {
    test('toMap and fromMap conversion works correctly', () {
      final now = DateTime.now();
      final msg = ChatMessageModel(
        id: 'msg_123',
        sender: 'user',
        content: 'Tell me about Pomodoro',
        timestamp: now,
        mode: 'generic',
      );

      final map = msg.toMap();
      expect(map['sender'], 'user');
      expect(map['content'], 'Tell me about Pomodoro');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['mode'], 'generic');

      final fromMap = ChatMessageModel.fromMap(map, 'msg_123');
      expect(fromMap.id, 'msg_123');
      expect(fromMap.sender, 'user');
      expect(fromMap.content, 'Tell me about Pomodoro');
      expect(fromMap.mode, 'generic');
      expect(fromMap.timestamp.year, now.year);
      expect(fromMap.timestamp.month, now.month);
    });

    test('copyWith updates fields correctly', () {
      final now = DateTime.now();
      final msg = ChatMessageModel(
        id: 'msg_123',
        sender: 'user',
        content: 'Original Content',
        timestamp: now,
        mode: 'generic',
      );

      final updated = msg.copyWith(
        sender: 'ai',
        content: 'Updated Content',
        mode: 'mentor',
      );

      expect(updated.id, 'msg_123');
      expect(updated.sender, 'ai');
      expect(updated.content, 'Updated Content');
      expect(updated.mode, 'mentor');
      expect(updated.timestamp, now);
    });
  });

  group('FirestoreStudentAIRepository AI Streaming Responses', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreStudentAIRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore({
        'exams': [
          {
            'userId': 'user_1',
            'subject': 'Computer Architecture',
            'examDate': '2026-07-15T10:00:00Z',
            'priority': 'High',
            'syllabus': 'Cache memory, Pipelining',
          }
        ],
        'subjects': [
          {
            'userId': 'user_1',
            'id': 'sub_comp_arch',
            'code': 'CS302',
            'name': 'Computer Architecture',
          }
        ],
        'attendance': [
          {
            'userId': 'user_1',
            'subjectId': 'sub_comp_arch',
            'status': 'present',
          },
          {
            'userId': 'user_1',
            'subjectId': 'sub_comp_arch',
            'status': 'absent',
          }
        ],
        'placement_progress': [
          {
            'userId': 'user_1',
            'company': 'Google',
            'role': 'Software Engineering Intern',
            'status': 'Interviewing',
            'salary': 'Competitive',
          }
        ],
        'goals': [
          {
            'userId': 'user_1',
            'title': 'Achieve 80% attendance',
            'isCompleted': false,
          }
        ],
        'focus_sessions': [
          {
            'userId': 'user_1',
            'completed': true,
            'durationMinutes': 45,
            'startTime': DateTime.now().toIso8601String(),
          }
        ]
      });

      repository = FirestoreStudentAIRepository(firestore: fakeFirestore);
    });

    test('streamResponse yields cumulative response text for generic Pomodoro query', () async {
      final stream = repository.streamResponse(
        prompt: 'Tell me about the Pomodoro Technique',
        history: [],
        userId: 'user_1',
        mode: 'generic',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);
      
      final finalResponse = chunks.last;
      expect(finalResponse.contains('Pomodoro Technique'), true);
      expect(finalResponse.contains('Francesco Cirillo'), true);
      expect(finalResponse.contains('25 minutes'), true);
    });

    test('streamResponse yields custom Connected Data responses for exams query', () async {
      final stream = repository.streamResponse(
        prompt: 'Summarize my upcoming exams',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('[Connected Data Mode Active]'), true);
      expect(finalResponse.contains('Computer Architecture'), true);
      expect(finalResponse.contains('Cache memory, Pipelining'), true);
    });

    test('streamResponse yields custom Mentor Mode responses for study tips and exams', () async {
      final stream = repository.streamResponse(
        prompt: 'Give me exam revision suggestions',
        history: [],
        userId: 'user_1',
        mode: 'mentor',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('[Student Mentor Mode Active]'), true);
      expect(finalResponse.contains('Computer Architecture'), true);
      expect(finalResponse.contains('spaced repetition'), true);
    });

    test('streamResponse yields custom Connected Data responses for attendance logs and warnings', () async {
      final stream = repository.streamResponse(
        prompt: 'Check my course attendance and warning status',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('**Computer Architecture (CS302)**: 50.0% attendance'), true);
      expect(finalResponse.contains('Attendance Alerts (Below 75%):'), true);
    });

    test('streamResponse yields custom Connected Data responses for focus sessions', () async {
      final stream = repository.streamResponse(
        prompt: 'How much focus time do I have logged today?',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('focus session statistics'), true);
      expect(finalResponse.contains('**Focus Today**: 45 minutes'), true);
    });

    test('streamResponse yields custom Connected Data responses for placements', () async {
      final stream = repository.streamResponse(
        prompt: 'How is my placement pipeline looking?',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('recruitment pipeline overview'), true);
      expect(finalResponse.contains('**Google (Software Engineering Intern)** — Status: **Interviewing**'), true);
    });

    test('streamResponse yields custom Connected Data responses for goals', () async {
      final stream = repository.streamResponse(
        prompt: 'What are my goals?',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('0 of 1 goals'), true);
      expect(finalResponse.contains('[ ] Achieve 80% attendance'), true);
    });

    test('streamResponse yields custom Connected Data responses for daily recommendations today', () async {
      final stream = repository.streamResponse(
        prompt: 'what should I do today?',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('daily action plan'), true);
      expect(finalResponse.contains('Study Recommendation:'), true);
    });

    test('streamResponse yields custom Connected Data responses for weekly productivity insights', () async {
      final stream = repository.streamResponse(
        prompt: 'how productive was I this week?',
        history: [],
        userId: 'user_1',
        mode: 'connected',
      );

      final List<String> chunks = await stream.toList();
      expect(chunks.isNotEmpty, true);

      final finalResponse = chunks.last;
      expect(finalResponse.contains('weekly productivity audit'), true);
      expect(finalResponse.contains('Total Focus Time'), true);
    });
  });
}
