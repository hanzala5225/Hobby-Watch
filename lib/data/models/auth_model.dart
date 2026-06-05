class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool isEmailVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.isEmailVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:               json['id'] ?? '',
    email:            json['email'] ?? '',
    fullName:         json['fullName'],
    avatarUrl:        json['avatarUrl'],
    isEmailVerified:  json['isEmailVerified'] ?? false,
    createdAt:        json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id':               id,
    'email':            email,
    'fullName':         fullName,
    'avatarUrl':        avatarUrl,
    'isEmailVerified':  isEmailVerified,
    'createdAt':        createdAt.toIso8601String(),
  };

  String get displayName => fullName ?? email.split('@').first;
  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthResponse(
      accessToken:  data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
      expiresAt:    data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'])
          : DateTime.now().add(const Duration(hours: 1)),
      user:         UserModel.fromJson(data['user'] ?? {}),
    );
  }
}
