// lib/features/community/domain/entities/community_message_entity.dart

import '../../../chat/domain/entities/message_entity.dart';

class CommunityMessageEntity {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;

  const CommunityMessageEntity({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
