import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 Added Supabase
import 'dart:io';
import '../models/message_model.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Future<void> sendMessage(MessageModel message);
  Future<void> saveChatThread(ChatModel chat);
  Stream<List<MessageModel>> watchMessages(String chatId);
  Stream<List<ChatModel>> watchChatThreads(String currentUserId);
  Future<void> markMessagesAsRead(String chatId, String currentUserId);
  Future<String> uploadImage(File imageFile);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase; // 🚀 Switched to Supabase Client

  ChatRemoteDataSourceImpl(this._firestore, this._supabase);

  @override
  Future<String> uploadImage(File imageFile) async {
    // Firestore auto-ID adds randomness so two uploads in the same millisecond can't collide
    final fileName =
        'chat_img_${DateTime.now().millisecondsSinceEpoch}_${_firestore.collection('messages').doc().id}.jpg';
    
    // 🚀 Upload to Supabase 'CHAT-IMAGES' bucket (with fallback for case matching)
    try {
      await _supabase.storage.from('CHAT-IMAGES').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _supabase.storage.from('CHAT-IMAGES').getPublicUrl(fileName);
    } catch (e) {
      // Fallback to lowercase 'chat-images' if uppercase bucket is not found
      await _supabase.storage.from('chat-images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _supabase.storage.from('chat-images').getPublicUrl(fileName);
    }
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    // 🚀 Saves message to 'messages' collection in the cloud
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toEntity().toJson()); // We'll add toJson next
  }

  @override
  Future<void> saveChatThread(ChatModel chat) async {
    // 🚀 Saves/Updates the chat row for the dashboard
    await _firestore
        .collection('chats')
        .doc(chat.id)
        .set(chat.toEntity().toJson());
  }

  // Both streams sort on the client instead of using orderBy, so no composite
  // Firestore indexes are required (where + orderBy on another field needs one).
  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data()))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  }

  @override
  Stream<List<ChatModel>> watchChatThreads(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc.data()))
            .toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime)));
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final unreadQuery = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();
    if (unreadQuery.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}