// lib/features/community/data/models/community_message_model.dart

import 'package:isar/isar.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../chat/domain/entities/message_entity.dart';
import '../../domain/entities/community_message_entity.dart';

part 'community_message_model.g.dart';

@Collection()
class CommunityMessageModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;

  @Index()
  final String communityId;

  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String? mediaUrl;
  final DateTime timestamp;

  CommunityMessageModel({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
  });

  factory CommunityMessageModel.fromEntity(CommunityMessageEntity entity) {
    return CommunityMessageModel(
      id: entity.id,
      communityId: entity.communityId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      text: entity.text,
      type: entity.type.name,
      mediaUrl: entity.mediaUrl,
      timestamp: entity.timestamp,
    );
  }

  CommunityMessageEntity toEntity() {
    return CommunityMessageEntity(
      id: id,
      communityId: communityId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: MessageType.values.firstWhere((e) => e.name == type, orElse: () => MessageType.text),
      mediaUrl: mediaUrl,
      timestamp: timestamp,
    );
  }

  factory CommunityMessageModel.fromFirestore(Map<String, dynamic> json) {
    return CommunityMessageModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      timestamp: DateParser.fromFirestore(json['timestamp']),
    );
  }
}
