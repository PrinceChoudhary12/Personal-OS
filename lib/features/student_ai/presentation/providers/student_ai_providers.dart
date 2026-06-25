// lib/features/student_ai/presentation/providers/student_ai_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/student_ai_repository.dart';
import '../../data/repositories/firestore_student_ai_repository.dart';

final studentAiRepositoryProvider = Provider<StudentAIRepository>((ref) {
  return FirestoreStudentAIRepository();
});
final studentAiSearchQueryProvider = StateProvider<String>((ref) => '');

final studentAiFilteredMessagesProvider = Provider<List<ChatMessageModel>>((ref) {
  final chatState = ref.watch(studentAiChatNotifierProvider);
  final searchQuery = ref.watch(studentAiSearchQueryProvider);
  if (searchQuery.trim().isEmpty) {
    return chatState.messages;
  }
  final query = searchQuery.toLowerCase().trim();
  return chatState.messages.where((m) => m.content.toLowerCase().contains(query)).toList();
});

class StudentAiChatState {
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String mode; // 'generic', 'connected', 'mentor'
  final List<String> suggestedQuestions;

  const StudentAiChatState({
    required this.messages,
    required this.isTyping,
    required this.mode,
    required this.suggestedQuestions,
  });

  StudentAiChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? mode,
    List<String>? suggestedQuestions,
  }) {
    return StudentAiChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      mode: mode ?? this.mode,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
    );
  }
}

final studentAiChatNotifierProvider =
    StateNotifierProvider<StudentAiChatNotifier, StudentAiChatState>((ref) {
  final repo = ref.watch(studentAiRepositoryProvider);
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  final userId = user?.uid ?? '';
  return StudentAiChatNotifier(repo: repo, userId: userId);
});

class StudentAiChatNotifier extends StateNotifier<StudentAiChatState> {
  final StudentAIRepository repo;
  final String userId;
  StreamSubscription<String>? _streamSub;

  StudentAiChatNotifier({required this.repo, required this.userId})
      : super(const StudentAiChatState(
          messages: [],
          isTyping: false,
          mode: 'generic',
          suggestedQuestions: [
            'How do I start a Pomodoro timer?',
            'Explain binary search trees.',
            'What is active recall?',
          ],
        )) {
    if (userId.isNotEmpty) {
      loadHistory();
    }
  }

  List<String> _getQuestionsForMode(String mode) {
    switch (mode) {
      case 'connected':
        return [
          'Summarize my academic standing.',
          'Do I have low attendance in any course?',
          'When is my next upcoming exam?',
        ];
      case 'mentor':
        return [
          'Give me study advice for my CS exams.',
          'Explain the Feynman technique.',
          'How do I prepare for a placement interview?',
        ];
      case 'generic':
      default:
        return [
          'How do I start a Pomodoro timer?',
          'Explain binary search trees.',
          'What is active recall?',
        ];
    }
  }

  Future<void> loadHistory() async {
    if (userId.isEmpty) return;
    final history = await repo.getChatHistory(userId);
    state = state.copyWith(messages: history);
  }

  void setMode(String newMode) {
    state = state.copyWith(
      mode: newMode,
      suggestedQuestions: _getQuestionsForMode(newMode),
    );
  }

  Future<void> clearHistory() async {
    if (userId.isEmpty) return;
    await repo.clearChatHistory(userId);
    state = state.copyWith(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (userId.isEmpty || text.trim().isEmpty) return;

    // 1. Add user message
    final userMsg = ChatMessageModel(
      id: '',
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
      mode: state.mode,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );
    await repo.saveMessage(userId, userMsg);

    // Refresh history
    await loadHistory();

    // 2. Prepare empty AI message in local list
    final tempAiId = 'temp_ai_${DateTime.now().millisecondsSinceEpoch}';
    final initialAiMsg = ChatMessageModel(
      id: tempAiId,
      sender: 'ai',
      content: '',
      timestamp: DateTime.now(),
      mode: state.mode,
    );
    
    state = state.copyWith(
      messages: [...state.messages, initialAiMsg],
    );

    // Cancel existing stream if any
    await _streamSub?.cancel();

    // 3. Listen to stream and update message content
    _streamSub = repo
        .streamResponse(
          prompt: text,
          history: state.messages.sublist(0, state.messages.length - 1),
          userId: userId,
          mode: state.mode,
        )
        .listen(
      (cumulativeContent) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == tempAiId) {
              return m.copyWith(content: cumulativeContent);
            }
            return m;
          }).toList(),
        );
      },
      onDone: () async {
        final finalMessageText = state.messages.firstWhere((m) => m.id == tempAiId).content;
        final finalizedAiMsg = ChatMessageModel(
          id: '',
          sender: 'ai',
          content: finalMessageText,
          timestamp: DateTime.now(),
          mode: state.mode,
        );

        // Remove temp message
        state = state.copyWith(
          messages: state.messages.where((m) => m.id != tempAiId).toList(),
        );

        await repo.saveMessage(userId, finalizedAiMsg);
        await loadHistory();
        state = state.copyWith(isTyping: false);
      },
      onError: (err) {
        state = state.copyWith(isTyping: false);
      },
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
