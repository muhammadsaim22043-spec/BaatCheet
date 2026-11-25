// lib/features/chat/presentation/controllers/chat_notifier.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/string_sanitizer.dart';
import '../../../ai/data/services/ai_service.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatNotifier extends ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatNotifier(this._chatRepository);

  // Live Stream Subscriptions to prevent memory leaks
  StreamSubscription<List<ChatEntity>>? _threadsSubscription;
  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  // Internal states
  List<ChatEntity> _chatThreads = [];
  List<ChatEntity> get chatThreads => _chatThreads;

  List<MessageEntity> _messages = [];
  List<MessageEntity> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
  }

  /// 📥 WATCH DASHBOARD THREADS
  /// Tunes into our local Isar database to watch for conversation changes globally.
  void listenToChatThreads(String currentUserId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _threadsSubscription?.cancel();
    _threadsSubscription = _chatRepository.getChatThreads(currentUserId).listen(
          (threads) {
        _chatThreads = threads;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// 📥 WATCH ACTIVE CONVERSATION BUBBLES
  /// Tunes into a specific chat thread to watch messages flying back and forth.
  void listenToMessages(String chatId) {
    _messages = []; // Clear old message history before opening a new room
    _isLoading = true;
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessages(chatId).listen(
          (newMessageList) {
        _messages = newMessageList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  bool _isMarkingRead = false;

  /// 🖋️ MARK AS READ
  /// Informs the database that the user has seen these messages.
  /// Skips the Firestore round-trip unless the loaded thread actually has
  /// unread incoming messages, since this runs on every UI update.
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final hasUnread = _messages.any((m) => m.receiverId == currentUserId && !m.isRead);
    if (!hasUnread || _isMarkingRead) return;

    _isMarkingRead = true;
    try {
      await _chatRepository.markMessagesAsRead(chatId, currentUserId);
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    } finally {
      _isMarkingRead = false;
    }
  }

  /// 📤 DISPATCH MESSAGE
  /// Sends a raw text message down our architecture pipe to local disk storage.
  Future<void> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    final cleanText = StringSanitizer.sanitize(text, maxLength: 2000);
    if (cleanText.isEmpty) return;

    final result = await _chatRepository.sendMessage(
      receiverId: receiverId,
      text: cleanText,
      type: MessageType.text,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        jsonRouteWorkaround();
        if (cleanText.toLowerCase().contains('@ai')) {
          _triggerAIResponse(receiverId, cleanText);
        }
      },
    );
  }

  Future<void> _triggerAIResponse(String receiverId, String userPrompt) async {
    try {
      final aiService = sl<AIService>();
      final responseText = await aiService.generateResponse(
        prompt: userPrompt,
        chatHistory: List.from(_messages),
      );

      await _chatRepository.sendMessage(
        receiverId: receiverId,
        text: responseText,
        type: MessageType.text,
      );
    } catch (e) {
      debugPrint('AI trigger error: $e');
    }
  }

  /// 📸 DISPATCH IMAGE MESSAGE
  Future<void> sendImageMessage({
    required String receiverId,
    required String imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    // 1. Upload to Cloud Storage first
    final uploadResult = await _chatRepository.uploadImage(imagePath);

    await uploadResult.fold(
      (failure) async {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (downloadUrl) async {
        // 2. Send message with the public URL
        final result = await _chatRepository.sendMessage(
          receiverId: receiverId,
          text: '', // Empty text for image-only messages
          type: MessageType.image,
          mediaUrl: downloadUrl,
        );

        result.fold(
          (failure) {
            _errorMessage = failure.message;
            _isLoading = false;
            notifyListeners();
          },
          (_) {
            _isLoading = false;
            jsonRouteWorkaround();
          },
        );
      },
    );
  }

  void jsonRouteWorkaround() {
    // Left empty intentionally—Isar's auto-stream watcher updates the UI for us!
  }

  @override
  void dispose() {
    // Crucial step: Shut down open pipelines when leaving a screen to save device battery
    _threadsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}