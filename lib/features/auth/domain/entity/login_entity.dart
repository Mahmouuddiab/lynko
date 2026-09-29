import 'package:equatable/equatable.dart';

class LoginEntity extends Equatable {
  final String message;
  final String accessToken;
  final DateTime expiresAt;
  final UserEntity user;

  const LoginEntity({
    required this.message,
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  @override
  List<Object?> get props => [message, accessToken, expiresAt, user];
}

class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
  });

  @override
  List<Object?> get props => [id, fullName, email];
}
