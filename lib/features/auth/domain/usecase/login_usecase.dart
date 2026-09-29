import 'package:lynko/core/params/login_params.dart';
import 'package:lynko/features/auth/domain/entity/login_entity.dart';
import 'package:lynko/features/auth/domain/repository/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repo;
  const LoginUseCase(this.repo);
  Future<LoginEntity> call(LoginParams loginParams) => repo.login(loginParams);
}
