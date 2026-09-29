import 'package:lynko/core/params/login_params.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/data/data%20source/auth_remote_ds.dart';
import 'package:lynko/features/auth/domain/entity/login_entity.dart';
import 'package:lynko/features/auth/domain/entity/register_entity.dart';
import 'package:lynko/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs remote;
  const AuthRepositoryImpl(this.remote);
  @override
  Future<RegisterEntity> register(RegisterParams registerParams) async {
    return await remote.register(registerParams);
  }

  @override
  Future<LoginEntity> login(LoginParams loginParams) async{
    return await remote.login(loginParams);
  }
}
