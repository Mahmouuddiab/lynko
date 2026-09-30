import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/profile/data/repository/profile_repository_impl.dart';
import 'package:lynko/features/profile/domain/entity/profile_entity.dart';
import 'package:lynko/features/profile/domain/repository/profile_repository.dart';
import 'package:lynko/features/profile/domain/usecase/get_profile_usecase.dart';
import '../../data/data source/profile_remote_ds.dart';

/// 1. Data Source Provider
final profileRemoteDsProvider = Provider<ProfileRemoteDs>((ref) {
  return ProfileRemoteDsImpl();
});

/// 2. Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDs = ref.watch(profileRemoteDsProvider);
  return ProfileRepositoryImpl(remoteDs);
});

/// 3. Use Case Provider
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfileUseCase(repository);
});

/// 4. Profile AsyncNotifier (Handles loading state, refresh, and data holding)
final profileNotifierProvider =
AsyncNotifierProvider<ProfileNotifier, ProfileEntity>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<ProfileEntity> {
  @override
  Future<ProfileEntity> build() async {
    return _fetchProfile();
  }

  Future<ProfileEntity> _fetchProfile() async {
    final getProfileUseCase = ref.read(getProfileUseCaseProvider);
    return await getProfileUseCase();
  }

  /// Callable method from UI to refresh profile data
  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }
}