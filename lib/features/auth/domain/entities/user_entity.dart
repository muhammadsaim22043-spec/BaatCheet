class UserEntity
{
  final String id;
  final String phoneNumber;
  final String displayName;
  final String avatarURL;
  final String email;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    required this.displayName,
    required this.avatarURL,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'avatarURL': avatarURL,
      'email': email,
    };
  }
}