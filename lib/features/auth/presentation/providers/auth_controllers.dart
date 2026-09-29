import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/presentation/providers/auth_providers.dart';
import 'package:lynko/core/params/login_params.dart';
import 'package:lynko/features/auth/domain/entity/login_entity.dart';

class RegisterController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> register({required RegisterParams registerParams}) async {
    final registerUseCase = ref.read(registerUseCaseProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await registerUseCase.call(registerParams);
    });
  }
}


class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<LoginEntity?> login({required LoginParams loginParams}) async {
    final loginUseCase = ref.read(loginUseCaseProvider);

    state = const AsyncLoading();

    LoginEntity? result;

    state = await AsyncValue.guard(() async {
      result = await loginUseCase.call(loginParams);
    });

    return result;
  }
}
