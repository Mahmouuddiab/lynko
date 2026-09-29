import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/auth/data/repository/auth_repository_impl.dart';
import 'package:lynko/features/auth/domain/repository/auth_repository.dart';
import 'package:lynko/features/auth/domain/usecase/login_usecase.dart';
import 'package:lynko/features/auth/domain/usecase/register_usecase.dart';
import 'package:lynko/features/auth/presentation/providers/auth_controllers.dart';

import '../../data/data source/auth_remote_ds.dart';

// 1. Remote Data Source Provider
final authRemoteDsProvider = Provider<AuthRemoteDs>((ref) {
  return AuthRemoteDsImpl();
});

// 2. Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDs = ref.watch(authRemoteDsProvider);
  return AuthRepositoryImpl(remoteDs);
});

// 3. Register UseCase Provider
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

// 4. Login UseCase Provider
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

// 5. Register Controller Provider (AsyncNotifier)
final registerControllerProvider =
AsyncNotifierProvider<RegisterController, void>(RegisterController.new);

// 6. Login Controller Provider (AsyncNotifier)
final loginControllerProvider =
AsyncNotifierProvider<LoginController, void>(LoginController.new);