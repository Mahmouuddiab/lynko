import 'package:lynko/core/params/login_params.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/domain/entity/login_entity.dart';
import 'package:lynko/features/auth/domain/entity/register_entity.dart';

abstract class AuthRepository {
  Future<RegisterEntity> register(RegisterParams registerParams);
  Future<LoginEntity> login(LoginParams loginParams);
}