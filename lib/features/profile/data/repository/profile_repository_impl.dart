import 'package:lynko/features/profile/data/data%20source/profile_remote_ds.dart';
import 'package:lynko/features/profile/domain/entity/profile_entity.dart';
import 'package:lynko/features/profile/domain/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDs remote;
  const ProfileRepositoryImpl(this.remote);

  @override
  Future<ProfileEntity> getProfile() async{
    return await remote.getProfile() ;
  }
}