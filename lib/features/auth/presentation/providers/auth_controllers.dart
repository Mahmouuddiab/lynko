import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/presentation/providers/auth_providers.dart';

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
