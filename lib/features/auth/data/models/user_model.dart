// lib/features/auth/data/models/user_model.dart

import 'package:isar/isar.dart';
import '../../domain/entities/user_entity.dart';

// This line tells the code generator to build a companion file named 'user_model.g.dart'
part 'user_model.g.dart';

@Collection()
class UserModel {
  // Isar database engines require a fast auto-incrementing integer for row lookup indexing
  Id isarId = Isar.autoIncrement;

  // We add an index to our global UUID text string for fast user searches
  @Index(unique: true, replace: true)
  final String id;

  final String phoneNumber;
  final String displayName;
  final String avatarUrl;
  final String email;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.displayName,
    required this.avatarUrl,
    required this.email,
  });

  /// 🔄 TRANSLATOR A: Takes a pure Domain Entity and packages it into a Database Model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      phoneNumber: entity.phoneNumber,
      displayName: entity.displayName,
      avatarUrl: entity.avatarURL,
      email: entity.email,
    );
  }

  /// 🔄 TRANSLATOR B: Takes this Database Model and strips away database dependencies to return a clean Entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      phoneNumber: phoneNumber,
      displayName: displayName,
      avatarURL: avatarUrl,
      email : email,
    );
  }

  /// 🔄 TRANSLATOR C: Takes a Firestore Map and packages it into a Database Model
  factory UserModel.fromFirestore(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarURL'] ?? '',
      email: json['email'] ?? '',
    );
  }
}