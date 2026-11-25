// lib/features/chat/data/models/message_model.dart

import 'package:isar/isar.dart';
import '../../../../core/utils/date_parser.dart';
import '../../domain/entities/message_entity.dart';

// The automated build runner will compile this companion file later
part 'message_model.g.dart';

@Collection()
class MessageModel {
  Id isarId = Isar.autoIncrement; // Isar's fast internal auto-incrementing key

  @Index(unique: true, replace: true)
  final String id; // Global unique message UUID string

  @Index()
  final String chatId; // 🔑 Indexed for lightning fast thread retrieval

  final String senderId;
  final String receiverId;
  final String text;
  final String type;     // 📸 'text', 'image', 'link'
  final String? mediaUrl;
  final DateTime timestamp;
  bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
  });

  /// 🔄 TRANSLATOR: Pure Entity ──▶ Isar Database Model
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      receiverId: entity.receiverId,
      text: entity.text,
      type: entity.type.name,
      mediaUrl: entity.mediaUrl,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
    );
  }

  /// 🔄 TRANSLATOR: Isar Database Model ──▶ Pure Clean Entity
  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: MessageType.values.firstWhere((e) => e.name == type, orElse: () => MessageType.text),
      mediaUrl: mediaUrl,
      timestamp: timestamp,
      isRead: isRead,
    );
  }

  /// 🔄 TRANSLATOR: Firestore Map ──▶ Database Model
  factory MessageModel.fromFirestore(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      timestamp: DateParser.fromFirestore(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}