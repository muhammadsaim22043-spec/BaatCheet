// lib/features/chat/domain/repositories/chat_repository.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {

  /// Dispatches a fresh message down the pipeline to be stored locally
  Future<Either<Failure, void>> sendMessage({
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  });

  /// Opens a live, permanent stream of all chat rows for the home dashboard
  Stream<List<ChatEntity>> getChatThreads(String currentUserId);

  /// Opens a live, permanent stream of the active conversation bubbles between two users
  Stream<List<MessageEntity>> getMessages(String chatId);

  /// 🖋️ MARK AS READ
  /// Updates all unread messages in a thread when a user opens the chat
  Future<void> markMessagesAsRead(String chatId, String currentUserId);

  /// 📸 UPLOAD IMAGE
  Future<Either<Failure, String>> uploadImage(String filePath);
}