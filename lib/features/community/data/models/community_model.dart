// lib/features/community/data/models/community_model.dart

import 'package:isar/isar.dart';
import '../../../../core/utils/date_parser.dart';
import '../../domain/entities/community_entity.dart';

part 'community_model.g.dart';

@Collection()
class CommunityModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;

  final String name;
  final String description;
  final String adminId;
  final List<String> memberIds;
  final bool isPublic;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? imageUrl;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.memberIds,
    required this.isPublic,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.imageUrl,
  });

  factory CommunityModel.fromEntity(CommunityEntity entity) {
    return CommunityModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      adminId: entity.adminId,
      memberIds: entity.memberIds,
      isPublic: entity.isPublic,
      createdAt: entity.createdAt,
      lastMessage: entity.lastMessage,
      lastMessageTime: entity.lastMessageTime,
      imageUrl: entity.imageUrl,
    );
  }

  CommunityEntity toEntity() {
    return CommunityEntity(
      id: id,
      name: name,
      description: description,
      adminId: adminId,
      memberIds: memberIds,
      isPublic: isPublic,
      createdAt: createdAt,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      imageUrl: imageUrl,
    );
  }

  factory CommunityModel.fromFirestore(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      adminId: json['adminId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      isPublic: json['isPublic'] ?? true,
      createdAt: DateParser.fromFirestore(json['createdAt']),
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateParser.fromFirestore(json['lastMessageTime'])
          : null,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'isPublic': isPublic,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toUtc().toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
