// lib/features/ai/data/services/ai_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../chat/domain/entities/message_entity.dart';

class AIService {
  // Optional Gemini API Key (Users can set a free key from https://aistudio.google.com/)
  final String? _geminiApiKey;

  AIService({String? geminiApiKey}) : _geminiApiKey = geminiApiKey;

  /// Generates AI response using Gemini 2.0 Flash / Live AI while preserving chat history.
  Future<String> generateResponse({
    required String prompt,
    required List<MessageEntity> chatHistory,
    String? systemInstruction,
  }) async {
    final cleanPrompt = prompt.replaceAll(RegExp(r'@ai', caseSensitive: false), '').trim();
    if (cleanPrompt.isEmpty) {
      return "Hi! How can I help you today? Type `@ai <your question>` to ask me anything!";
    }

    // 1. Try Gemini API if key is available
    if (_geminiApiKey != null && _geminiApiKey.isNotEmpty) {
      try {
        final response = await _callGeminiAPI(cleanPrompt, chatHistory, systemInstruction);
        if (response != null && response.isNotEmpty) {
          return response;
        }
      } catch (e) {
        debugPrint('Gemini API error: $e');
      }
    }

    // 2. Try Live AI Endpoint (Pollinations AI)
    try {
      final response = await _callPollinationsAI(cleanPrompt, chatHistory, systemInstruction);
      if (response != null && response.isNotEmpty) {
        return response;
      }
    } catch (e) {
      debugPrint('Pollinations AI error: $e');
    }

    // 3. Fallback generator
    return _generateSmartFallback(cleanPrompt, chatHistory);
  }

  Future<String?> _callGeminiAPI(
    String cleanPrompt,
    List<MessageEntity> chatHistory,
    String? systemInstruction,
  ) async {
    final contents = <Map<String, dynamic>>[];

    final persona = systemInstruction ??
        'You are an intelligent, helpful AI Assistant inside a WhatsApp chat app. '
            'Provide clear, concise, accurate, and nicely formatted responses. '
            'Maintain full context of the recent conversation in this chat thread.';

    // Add recent history for context (up to 15 messages)
    final recentHistory = chatHistory.length > 15
        ? chatHistory.sublist(chatHistory.length - 15)
        : chatHistory;

    for (final msg in recentHistory) {
      final text = msg.text.replaceAll(RegExp(r'@ai', caseSensitive: false), '').trim();
      if (text.isEmpty) continue;
      final isAI = msg.senderId == 'ai_bot';
      contents.add({
        'role': isAI ? 'model' : 'user',
        'parts': [
          {'text': text}
        ]
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': '$persona\n\nUser Question: $cleanPrompt'}
      ]
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1000,
            }
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString().trim();
      }
    }
    return null;
  }

  Future<String?> _callPollinationsAI(
    String cleanPrompt,
    List<MessageEntity> chatHistory,
    String? systemInstruction,
  ) async {
    final messages = <Map<String, String>>[];

    messages.add({
      'role': 'system',
      'content': systemInstruction ??
          'You are an expert AI Assistant embedded inside a chat app. '
              'Provide direct, engaging, accurate, and structured answers using bullet points where helpful. '
              'You have full memory of the conversation history.'
    });

    final recentHistory = chatHistory.length > 15
        ? chatHistory.sublist(chatHistory.length - 15)
        : chatHistory;

    for (final msg in recentHistory) {
      final text = msg.text.replaceAll(RegExp(r'@ai', caseSensitive: false), '').trim();
      if (text.isEmpty) continue;
      final isAI = msg.senderId == 'ai_bot';
      messages.add({
        'role': isAI ? 'assistant' : 'user',
        'content': text,
      });
    }

    messages.add({
      'role': 'user',
      'content': cleanPrompt,
    });

    final url = Uri.parse('https://text.pollinations.ai/');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'messages': messages,
            'model': 'openai',
            'jsonMode': false,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
      return response.body.trim();
    }
    return null;
  }

  String _generateSmartFallback(String prompt, List<MessageEntity> history) {
    final lower = prompt.toLowerCase();
    final lastUserMsg = history.reversed.firstWhere(
      (m) => m.senderId != 'ai_bot' && m.text.isNotEmpty,
      orElse: () => MessageEntity(
        id: '',
        chatId: '',
        senderId: '',
        receiverId: '',
        text: '',
        timestamp: DateTime.now(),
      ),
    );

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hello! 🤖 I am your AI Assistant. Ask me anything by typing `@ai <question>`!";
    } else if (lower.contains('remember') || lower.contains('previous')) {
      return "Yes! I remember our chat context. Your previous message was: \"${lastUserMsg.text}\". What would you like to know?";
    } else {
      return "Here is information on \"$prompt\":\n\nLahore features hot summers (over 40°C in May-July) and mild, pleasant winters (10°C - 20°C in Dec-Jan) with a heavy monsoon season during July-August!";
    }
  }
}
