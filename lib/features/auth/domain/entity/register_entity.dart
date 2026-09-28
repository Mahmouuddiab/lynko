class RegisterEntity {
  final String message;
  final UserEntity user;

  const RegisterEntity({
    required this.message,
    required this.user,
  });
}

class UserEntity {
  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });
}