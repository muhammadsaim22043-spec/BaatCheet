// lib/features/chat/domain/entities/chat_entity.dart

class ChatEntity {
  final String id;                // Unique ID for this specific conversation thread
  final List<String> participantIds; // Array containing both user IDs [You, Friend]
  final String lastMessage;       // Preview text shown on the home dashboard list row
  final DateTime lastMessageTime; // Timestamp used to sort chats from newest to oldest

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toUtc().toIso8601String(),
    };
  }
}