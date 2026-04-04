class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isOnboarded;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.isOnboarded,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
      isOnboarded: json['is_onboarded'] ?? false,
    );
  }
}
