import '../../domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
  });

  /// Factory constructor to map JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }

  /// Converts UserModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
    };
  }

}