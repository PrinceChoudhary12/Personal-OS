// lib/features/student_ai/domain/repositories/student_ai_repository.dart

import '../models/chat_message_model.dart';

abstract class StudentAIRepository {
  Stream<String> streamResponse({
    required String prompt,
    required List<ChatMessageModel> history,
    required String userId,
    required String mode,
  });

  Future<List<ChatMessageModel>> getChatHistory(String userId);

  Future<void> saveMessage(String userId, ChatMessageModel message);

  Future<void> clearChatHistory(String userId);
}
