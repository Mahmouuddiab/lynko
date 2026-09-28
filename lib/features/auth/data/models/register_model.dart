
import 'package:lynko/features/auth/domain/entity/register_entity.dart';

class RegisterModel extends RegisterEntity {
  const RegisterModel({
    required super.message,
    required super.user,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      message: json['message'] ?? '',
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}