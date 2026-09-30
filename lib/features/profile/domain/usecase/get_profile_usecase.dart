import 'package:lynko/features/profile/domain/entity/profile_entity.dart';
import 'package:lynko/features/profile/domain/repository/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repo;
  const GetProfileUseCase(this.repo);
  Future<ProfileEntity> call() => repo.getProfile();
}
