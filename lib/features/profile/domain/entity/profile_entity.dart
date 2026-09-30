import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  const ProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, fullName, email, createdAt];
}