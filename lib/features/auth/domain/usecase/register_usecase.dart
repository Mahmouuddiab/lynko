import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/domain/entity/register_entity.dart';
import 'package:lynko/features/auth/domain/repository/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repo;
  const RegisterUseCase(this.repo);
  Future<RegisterEntity> call(RegisterParams registerParams) =>
      repo.register(registerParams);
}
