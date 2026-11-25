// lib/features/community/domain/entities/community_entity.dart

class CommunityEntity {
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

  const CommunityEntity({
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

  CommunityEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    List<String>? memberIds,
    bool? isPublic,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? imageUrl,
  }) {
    return CommunityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
