// lib/features/chat/data/models/chat_model.dart

import 'package:isar/isar.dart';
import '../../../../core/utils/date_parser.dart';
import '../../domain/entities/chat_entity.dart';

part 'chat_model.g.dart';

@Collection()
class ChatModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id; // Unique conversation thread ID

  final List<String> participantIds; // Maps [UserA_ID, UserB_ID]
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  /// 🔄 TRANSLATOR: Pure Entity ──▶ Isar Database Model
  factory ChatModel.fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      participantIds: entity.participantIds,
      lastMessage: entity.lastMessage,
      lastMessageTime: entity.lastMessageTime,
    );
  }

  /// 🔄 TRANSLATOR: Isar Database Model ──▶ Pure Clean Entity
  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      participantIds: participantIds,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
    );
  }

  /// 🔄 TRANSLATOR: Firestore Map ──▶ Database Model
  factory ChatModel.fromFirestore(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      participantIds: List<String>.from(json['participantIds'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateParser.fromFirestore(json['lastMessageTime']),
    );
  }
}