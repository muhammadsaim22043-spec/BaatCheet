// lib/features/chat/data/datasources/chat_local_data_source.dart

import 'package:isar/isar.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatLocalDataSource {
  Future<void> saveMessage(MessageModel message);
  Future<void> saveChatThread(ChatModel chat);
  Stream<List<ChatModel>> watchChatThreads(String currentUserId);
  Stream<List<MessageModel>> watchMessages(String chatId);
  Future<void> markMessagesAsRead(String chatId, String currentUserId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final Isar _isar;

  ChatLocalDataSourceImpl(this._isar);

  @override
  Future<void> saveMessage(MessageModel message) async {
    await _isar.writeTxn(() async {
      await _isar.messageModels.put(message);
    });
  }

  @override
  Future<void> saveChatThread(ChatModel chat) async {
    await _isar.writeTxn(() async {
      await _isar.chatModels.put(chat);
    });
  }

  @override
  Stream<List<ChatModel>> watchChatThreads(String currentUserId) {
    // Returns a live database stream sorted with the newest conversations at the top
    return _isar.chatModels
        .filter()
        .participantIdsElementEqualTo(currentUserId)
        .sortByLastMessageTimeDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    // Listens for all messages belonging to this specific unique conversation thread
    return _isar.messageModels
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestamp()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    await _isar.writeTxn(() async {
      final unreadMessages = await _isar.messageModels
          .filter()
          .chatIdEqualTo(chatId)
          .and()
          .receiverIdEqualTo(currentUserId) // Only mark those RECEIVED by current user
          .and()
          .isReadEqualTo(false)
          .findAll();

      for (var msg in unreadMessages) {
        msg.isRead = true;
      }
      
      // Batch save the updated status
      if (unreadMessages.isNotEmpty) {
        await _isar.messageModels.putAll(unreadMessages);
      }
    });
  }
}