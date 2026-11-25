// lib/features/community/presentation/controllers/community_notifier.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../ai/data/services/ai_service.dart';
import '../../../chat/domain/entities/message_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/community_message_entity.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityNotifier extends ChangeNotifier {
  final CommunityRepository _repository;

  CommunityNotifier(this._repository);

  StreamSubscription<List<CommunityEntity>>? _communitiesSubscription;
  StreamSubscription<List<CommunityMessageEntity>>? _messagesSubscription;

  List<CommunityEntity> _userCommunities = [];
  List<CommunityEntity> get userCommunities => _userCommunities;

  List<CommunityEntity> _searchResults = [];
  List<CommunityEntity> get searchResults => _searchResults;

  List<CommunityMessageEntity> _messages = [];
  List<CommunityMessageEntity> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
  }

  void listenToUserCommunities(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _communitiesSubscription?.cancel();
    _communitiesSubscription = _repository.watchUserCommunities(userId).listen(
      (communities) {
        _userCommunities = communities;
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

  Future<void> searchPublicCommunities(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final result = await _repository.searchPublicCommunities(query);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSearching = false;
        notifyListeners();
      },
      (communities) {
        _searchResults = communities;
        _isSearching = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createCommunity({
    required String name,
    required String description,
    required String adminId,
    required bool isPublic,
    List<String>? initialMemberIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    final id = 'comm_${DateTime.now().millisecondsSinceEpoch}';
    final members = <String>{adminId, ...?initialMemberIds}.toList();

    final community = CommunityEntity(
      id: id,
      name: name,
      description: description,
      adminId: adminId,
      memberIds: members,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );

    final result = await _repository.createCommunity(community);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.joinCommunity(communityId, userId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addMemberToCommunity({
    required String communityId,
    required String memberId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.addMemberToCommunity(communityId, memberId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  void listenToCommunityMessages(String communityId) {
    _messages = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _repository.watchCommunityMessages(communityId).listen(
      (messages) {
        _messages = messages;
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

  Future<void> sendTextMessage({
    required String communityId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = CommunityMessageEntity(
      id: 'cmsg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    final result = await _repository.sendCommunityMessage(message);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        if (text.toLowerCase().contains('@ai')) {
          _triggerAIResponse(communityId, text);
        }
      },
    );
  }

  Future<void> _triggerAIResponse(String communityId, String userPrompt) async {
    try {
      final aiService = sl<AIService>();
      final history = _messages
          .map((m) => MessageEntity(
                id: m.id,
                chatId: m.communityId,
                senderId: m.senderId,
                receiverId: communityId,
                text: m.text,
                timestamp: m.timestamp,
              ))
          .toList();

      final responseText = await aiService.generateResponse(
        prompt: userPrompt,
        chatHistory: history,
      );

      final aiMessage = CommunityMessageEntity(
        id: 'cmsg_ai_${DateTime.now().millisecondsSinceEpoch}',
        communityId: communityId,
        senderId: 'ai_bot',
        senderName: '🤖 AI Assistant',
        text: responseText,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      await _repository.sendCommunityMessage(aiMessage);
    } catch (e) {
      debugPrint('AI trigger error in community: $e');
    }
  }

  Future<void> sendImageMessage({
    required String communityId,
    required String senderId,
    required String senderName,
    required String imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    final uploadResult = await _repository.uploadImage(imagePath);

    await uploadResult.fold(
      (failure) async {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (downloadUrl) async {
        final message = CommunityMessageEntity(
          id: 'cmsg_${DateTime.now().millisecondsSinceEpoch}',
          communityId: communityId,
          senderId: senderId,
          senderName: senderName,
          text: '',
          type: MessageType.image,
          mediaUrl: downloadUrl,
          timestamp: DateTime.now(),
        );

        final result = await _repository.sendCommunityMessage(message);

        result.fold(
          (failure) {
            _errorMessage = failure.message;
            _isLoading = false;
            notifyListeners();
          },
          (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _communitiesSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
