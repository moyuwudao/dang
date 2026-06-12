class UserModel {
  final String id;
  final String phone;
  final String? nickname;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool hasPassword;

  const UserModel({
    required this.id,
    required this.phone,
    this.nickname,
    this.avatarUrl,
    required this.createdAt,
    this.hasPassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      hasPassword: json['hasPassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'hasPassword': hasPassword,
    };
  }
}
