import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String email;
  final String fullName;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
  });

  @override
  List<Object?> get props => [id, email, fullName];
}