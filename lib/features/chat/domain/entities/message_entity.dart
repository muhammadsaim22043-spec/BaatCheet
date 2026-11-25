// lib/features/chat/domain/entities/message_entity.dart

enum MessageType { text, image, link }

class MessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;   // 📸 text, image, or link
  final String? mediaUrl;   // 🔗 Path to the image or the URL link
  final DateTime timestamp;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'isRead': isRead,
    };
  }
}