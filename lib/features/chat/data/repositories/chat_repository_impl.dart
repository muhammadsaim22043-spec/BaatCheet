// lib/features/chat/data/repositories/chat_repository_impl.dart

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _localDataSource;
  final ChatRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  ChatRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._secureStorage,
  );

  @override
  Future<Either<Failure, void>> sendMessage({
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      // 1. Unmask your own user ID from the encrypted hardware storage vault
      final currentUserId = await _secureStorage.read(key: 'active_user_session_id');
      if (currentUserId == null) {
        return const Left(AuthFailure('No active user session found.'));
      }

      final timestamp = DateTime.now();
      // Include the sender so two users messaging in the same millisecond can't overwrite each other
      final messageId = 'msg_${timestamp.millisecondsSinceEpoch}_$currentUserId';

      // 2. Generate a standard unique ID for this specific 2-person chat thread
      // (Sorting the IDs alphabetically ensures both users point to the exact same thread ID)
      final sortedIds = [currentUserId, receiverId]..sort();
      final chatId = 'chat_${sortedIds.join('_')}';

      // 3. Construct and write the message model to both Isar and Firestore
      final newMessage = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        text: text,
        type: type.name, // 📸 text, image, or link
        mediaUrl: mediaUrl,
        timestamp: timestamp,
      );
      
      // Save locally (Offline-first)
      await _localDataSource.saveMessage(newMessage);
      // Save to Cloud (Internet)
      await _remoteDataSource.sendMessage(newMessage);

      // 4. Update or create the Chat Row summary for both
      final updatedChatThread = ChatModel(
        id: chatId,
        participantIds: sortedIds,
        lastMessage: type == MessageType.image ? '📸 Photo' : text,
        lastMessageTime: timestamp,
      );
      
      await _localDataSource.saveChatThread(updatedChatThread);
      await _remoteDataSource.saveChatThread(updatedChatThread);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to dispatch local message: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ChatEntity>> getChatThreads(String currentUserId) {
    // Switch to Remote Stream for real-time sync between devices
    return _remoteDataSource.watchChatThreads(currentUserId).map(
          (modelList) => modelList.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    // Switch to Remote Stream for real-time sync between devices
    return _remoteDataSource.watchMessages(chatId).map(
          (modelList) => modelList.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    // Mark read on both local and cloud
    await _localDataSource.markMessagesAsRead(chatId, currentUserId);
    await _remoteDataSource.markMessagesAsRead(chatId, currentUserId);
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      final downloadUrl = await _remoteDataSource.uploadImage(file);
      return Right(downloadUrl);
    } catch (e) {
      return Left(CacheFailure('Failed to upload image: ${e.toString()}'));
    }
  }
}