import 'package:lynko/features/auth/domain/entity/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.message,
    required super.accessToken,
    required super.expiresAt,
    required super.user,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      message: json['message'] ?? '',
      accessToken: json['accessToken'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': (user as UserModel).toJson(),
    };
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'email': email};
  }
}
